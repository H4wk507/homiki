# rl/train.py
import sys
import numpy as np
from tqdm import tqdm
import matplotlib.pyplot as plt
import os
import random

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'python')))
from sim.game import GameSim
from ppo_agent import PPOAgent, PPOConfig

def extract_state(obs, info, sim):
    """Convert observation + info into state vector for RL"""
    x, y, xvel, yvel = obs
    
    # Normalize positions and velocities
    x_norm = x / 10000.0
    y_norm = (y - 950) / 1000.0
    xvel_norm = np.tanh(xvel / 200.0)
    yvel_norm = np.tanh(yvel / 200.0)
    grav_points_norm = sim.grav_points / sim.grav_points_max

    jumping = float(info.get('jumping', False))
    hamster_yvel = info.get('hamster_yvel', 0)
    yvel_direction = 1.0 if hamster_yvel < 0 else -1.0  # -1=rising, 1=falling

    nearest_dx = 0.0
    nearest_dy = 0.0
    nearest_type = np.zeros(6, dtype=np.float32) # one hot for [bounce, speed, wind, slide, rebound, superbounce]

    if sim.powerups:
        b = sim.bullet
        if b is not None:
            nearest = min(sim.powerups, key=lambda p: abs(p['x'] - b.x))
            nearest_dx = (nearest['x'] - b.x) / 5000.0
            nearest_dy = (nearest['y'] - b.y) / 1000.0
            type_idx = ["bounce", "speed", "wind", "slide", "rebound", "superbounce"].index(nearest['typ'])
            nearest_type[type_idx] = 1.0
    
    state = np.concatenate([
        np.array([
            x_norm,
            y_norm,
            xvel_norm,
            yvel_norm,
            grav_points_norm,
            float(info.get('falling', False)),
            float(info.get('skidding', False)),
            float(info.get('ground', False)),
            float(info.get('jumping', False)),  # Add jumping flag
            float(info.get('meter', 0)) / 100.0,  # Add meter position
            yvel_direction * jumping,
            nearest_dx,
            nearest_dy
        ], dtype=np.float32),
        nearest_type
    ])
    
    return state


def train_ppo(agent, num_episodes=15000, steps_per_update=2048, save_every=100):
    episode_rewards = []
    episode_distances = []
    launch_success_rate = []

    agent.config.entropy_coef = 0.1
    agent.config.clip_epsilon = 0.15
    agent.config.ppo_epochs = 6
    agent.config.batch_size = 128
    
    pbar = tqdm(range(num_episodes), desc="Training")
    
    for episode in pbar:
        sim = GameSim()
        sim.jump()

        if episode > 5000:
            sim.powerup_mark = 500 + random.randint(0, 300)
            sim.grav_points_max = random.choice([80, 100, 120])
            for p in range(random.randint(3, 8)):
                sim._generate_powerup()
        
        obs, _, _, info = sim.step(action=0)
        state = extract_state(obs, info, sim)
        
        episode_reward = 0
        step_count = 0
        done = False
        launched = False
        
        # Curriculum with demonstration
        demo_prob = max(0.3 - episode / 30000, 0)
        use_expert_demo = random.random() < demo_prob
        forced_launch = False
        
        while not done and step_count < 5000:
            # Expert demonstration: launch in optimal range
            if use_expert_demo and info.get('jumping', False) and not forced_launch:
                meter = info.get('meter', 0) / 100.0
                # Expert policy: launch when meter is 0.5-0.7 AND falling
                yvel = info.get('hamster_yvel', 0)
                if 0.5 <= meter <= 0.7 and yvel > 0 and random.random() < 0.4:
                    action = 1
                    forced_launch = True
                else:
                    action, log_prob, value = agent.select_action(state)
            else:
                action, log_prob, value = agent.select_action(state)
            
            obs, reward, done, info = sim.step(action)

            # Reward shaping
            if info.get('jumping', False):
                meter = info.get('meter', 0) / 100.0
                yvel = info.get('hamster_yvel', 0)
                if action == 1:
                    if 0.5 <= meter <= 0.7 and yvel > 0:
                        reward += 10.0
                    elif 0.45 <= meter <= 0.75:
                        reward += 2.0
                    else:
                        reward -= 1.0
            else:
                if sim.bullet:
                    reward += max(0, sim.bullet.xvel) / 100.0
                    if not info.get('ground', False):
                        reward += 0.02
                    if 'collected' in info:
                        reward += 5.0
                    if sim.faceplant:
                        reward -= 20.0

            
            # Dense reward shaping during jump
            if info.get('jumping', False):
                meter = info.get('meter', 0) / 100.0
                yvel = info.get('hamster_yvel', 0)
                
                if action == 1:  # Pressed launch
                    # Reward for launching in good zone
                    if 0.5 <= meter <= 0.7 and yvel > 0:  # Optimal: falling in good range
                        reward += 2.0
                    elif 0.45 <= meter <= 0.75:  # Acceptable
                        reward += 0.5
                    else:  # Bad timing
                        reward -= 0.5
            
            # Launch outcome
            prev_jumping = state[8] > 0.5
            curr_jumping = info.get('jumping', False)
            
            if prev_jumping and not curr_jumping:
                if sim.bullet is not None:
                    reward += 20.0  # Huge reward for success
                    launched = True
                else:
                    reward -= 10.0  # Big penalty for failure
                    done = True
            # Flight rewards
            if launched and sim.bullet:
                dist = sim.bullet.x / 100.0
                reward += 0.05
                if dist > 100: reward += 0.5
                if dist > 200: reward += 1.0
                if dist > 400: reward += 2.0
                if dist > 600: reward += 4.0
                if dist > 800: reward += 6.0
                if dist > 1000: reward += 10.0

                if abs(sim.bullet.yvel) < 5 and abs(sim.bullet.xvel) > 50:
                    reward += 2.0
            
            if sim.faceplant:
                reward -= 5.0
            
            
            next_state = extract_state(obs, info, sim)
            agent.buffer.add(state, action, reward, value, log_prob, done)
            
            episode_reward += reward
            state = next_state
            step_count += 1
            
            if len(agent.buffer.states) >= steps_per_update:
                agent.update(next_state)
        
        if len(agent.buffer.states) > 0:
            agent.update(state)
        
        # Metrics
        final_distance = sim.bullet.x / 100.0 if sim.bullet else 0.0
        episode_rewards.append(episode_reward)
        episode_distances.append(final_distance)
        launch_success_rate.append(float(launched))
        
        # Progress
        window = 100
        avg_reward = np.mean(episode_rewards[-window:])
        avg_distance = np.mean(episode_distances[-window:])
        avg_launch_rate = np.mean(launch_success_rate[-window:])
        
        pbar.set_postfix({
            'rew': f'{avg_reward:.1f}',
            'dist': f'{avg_distance:.1f}ft',
            'L%': f'{avg_launch_rate*100:.0f}',
        })
        
        # Save and plot (same as before)
        if (episode + 1) % save_every == 0:
            agent.save(f'checkpoints/ppo_episode_{episode+1}.pt')
            
            plt.figure(figsize=(15, 4))
            
            plt.subplot(1, 3, 1)
            plt.plot(episode_rewards, alpha=0.3)
            if len(episode_rewards) >= 100:
                plt.plot(np.convolve(episode_rewards, np.ones(100)/100, mode='valid'), linewidth=2)
            plt.title('Episode Rewards')
            plt.xlabel('Episode')
            plt.grid(alpha=0.3)
            
            plt.subplot(1, 3, 2)
            plt.plot(episode_distances, alpha=0.3)
            if len(episode_distances) >= 100:
                plt.plot(np.convolve(episode_distances, np.ones(100)/100, mode='valid'), linewidth=2)
            plt.title('Distance (ft)')
            plt.xlabel('Episode')
            plt.grid(alpha=0.3)
            
            plt.subplot(1, 3, 3)
            if len(launch_success_rate) >= 100:
                plt.plot(np.convolve(launch_success_rate, np.ones(100)/100, mode='valid'), linewidth=2)
            plt.title('Launch Success %')
            plt.xlabel('Episode')
            plt.ylim([0, 1.1])
            plt.grid(alpha=0.3)
            
            plt.tight_layout()
            plt.savefig(f'checkpoints/progress_{episode+1}.png')
            plt.close()
    
    return agent, episode_rewards, episode_distances


if __name__ == '__main__':
    import os
    import argparse

    os.makedirs('checkpoints', exist_ok=True)

    parser = argparse.ArgumentParser(description="Train PPO agent for Homiki game")
    parser.add_argument('--episodes', type=int, default=15000, help='Number of episodes to train')
    parser.add_argument('--resume', type=str, default=None, help='Path to checkpoint to resume from')
    args = parser.parse_args()

    config = PPOConfig(state_dim=19)
    agent = PPOAgent(config)

    start_episode = 0
    if args.resume is not None and os.path.exists(args.resume):
        print(f"Resuming training from checkpoint: {args.resume}")
        agent.load(args.resume)

        import re
        match = re.search(r'(\d+)', os.path.basename(args.resume))
        if match:
            start_episode = int(match.group(1))
            print(f"Resuming from episode {start_episode}")
        else:
            print("Could not parse episode number, starting counter from 0")

        # optional: lower learning rate for fine-tuning
        agent.optimizer.param_groups[0]['lr'] = 1e-4
    else:
        print("Starting new training session")
    
    _, rewards, distances = train_ppo(
        agent,
        num_episodes=args.episodes,
        steps_per_update=4096,
        save_every=100
    )
    
    print(f"\nTraining complete!")
    print(f"Final avg reward (last 100): {np.mean(rewards[-100:]):.2f}")
    print(f"Final avg distance (last 100): {np.mean(distances[-100:]):.1f}ft")

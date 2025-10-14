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
    xvel_norm = np.clip(xvel / 100.0, -2, 2)
    yvel_norm = np.clip(yvel / 100.0, -2, 2)
    grav_points_norm = sim.grav_points / sim.grav_points_max

    jumping = float(info.get('jumping', False))
    hamster_yvel = info.get('hamster_yvel', 0)
    yvel_direction = 1.0 if hamster_yvel < 0 else -1.0  # -1=rising, 1=falling
    
    state = np.array([
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
        yvel_direction * jumping,  # NEW: velocity direction during jump
    ], dtype=np.float32)
    
    return state


def train_ppo(num_episodes=15000, steps_per_update=2048, save_every=100):  # More episodes
    config = PPOConfig(state_dim=11)  # Updated to 11
    agent = PPOAgent(config)
    
    episode_rewards = []
    episode_distances = []
    launch_success_rate = []
    
    pbar = tqdm(range(num_episodes), desc="Training")
    
    for episode in pbar:
        sim = GameSim()
        sim.jump()
        
        obs, _, _, info = sim.step(action=0)
        state = extract_state(obs, info, sim)
        
        episode_reward = 0
        step_count = 0
        done = False
        launched = False
        
        # Curriculum with demonstration
        use_expert_demo = episode < 2000  # First 2000 episodes
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
                # Small continuous reward for distance
                if step_count % 10 == 0:
                    reward += 0.1
            
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
    os.makedirs('checkpoints', exist_ok=True)
    
    agent, rewards, distances = train_ppo(
        num_episodes=15000,
        steps_per_update=2048,
        save_every=100
    )
    
    print(f"\nTraining complete!")
    print(f"Final avg reward (last 100): {np.mean(rewards[-100:]):.2f}")
    print(f"Final avg distance (last 100): {np.mean(distances[-100:]):.1f}ft")

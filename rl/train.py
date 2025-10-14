# rl/train.py
import sys
import numpy as np
from tqdm import tqdm
import matplotlib.pyplot as plt
import os

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
    ], dtype=np.float32)
    
    return state

def train_ppo(num_episodes=10000, steps_per_update=2048, save_every=100):
    config = PPOConfig(state_dim=10)
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
        
        # Track for shaped rewards
        launch_attempt_made = False
        
        while not done and step_count < 5000:
            action, log_prob, value = agent.select_action(state)
            
            # Track if agent tries to launch during jump
            if info.get('jumping', False) and action == 1:
                launch_attempt_made = True
            
            obs, reward, done, info = sim.step(action)
            
            # CRITICAL: Reward shaping for jump/launch phase
            if info.get('jumping', False):
                # Encourage pressing launch in good meter range
                meter = info.get('meter', 0) / 100.0
                
                if action == 1:  # Pressed launch
                    # Reward based on meter position (sweet spot is 40-70%)
                    if 0.4 <= meter <= 0.7:
                        reward += 0.5  # Good timing window
                    elif 0.3 <= meter <= 0.8:
                        reward += 0.2  # Okay timing
                    else:
                        reward -= 0.1  # Bad timing
            
            # Launch outcome (previous jumping=True, now jumping=False)
            prev_jumping = state[8] > 0.5  # jumping flag from previous state
            curr_jumping = info.get('jumping', False)
            
            if prev_jumping and not curr_jumping:  # Jump just ended
                if sim.bullet is not None:
                    # SUCCESS! Launched the hamster
                    reward += 10.0  # Big reward
                    launched = True
                else:
                    # FAILURE! Missed the pillow or faceplant
                    reward -= 5.0  # Big penalty
                    done = True
            
            # Flight phase rewards (after successful launch)
            if launched and sim.bullet is not None:
                # Continuous reward for distance traveled
                # This is already in the step() reward from sim
                pass
            
            next_state = extract_state(obs, info, sim)
            agent.buffer.add(state, action, reward, value, log_prob, done)
            
            episode_reward += reward
            state = next_state
            step_count += 1
            
            if len(agent.buffer.states) >= steps_per_update:
                metrics = agent.update(next_state)
        
        if len(agent.buffer.states) > 0:
            metrics = agent.update(state)
        
        # Track metrics
        final_distance = sim.bullet.x / 100.0 if sim.bullet else 0.0
        episode_rewards.append(episode_reward)
        episode_distances.append(final_distance)
        launch_success_rate.append(float(launched))
        
        # Update progress bar
        avg_reward = np.mean(episode_rewards[-100:])
        avg_distance = np.mean(episode_distances[-100:])
        avg_launch_rate = np.mean(launch_success_rate[-100:])
        
        pbar.set_postfix({
            'rew': f'{avg_reward:.1f}',
            'dist': f'{avg_distance:.1f}ft',
            'launch%': f'{avg_launch_rate*100:.0f}',
        })
        
        # Save checkpoint
        if (episode + 1) % save_every == 0:
            agent.save(f'checkpoints/ppo_episode_{episode+1}.pt')
            
            # Plot progress
            plt.figure(figsize=(15, 4))
            
            plt.subplot(1, 3, 1)
            plt.plot(episode_rewards, alpha=0.3)
            if len(episode_rewards) >= 100:
                plt.plot(np.convolve(episode_rewards, np.ones(100)/100, mode='valid'), linewidth=2)
            plt.title('Episode Rewards')
            plt.xlabel('Episode')
            plt.ylabel('Reward')
            plt.grid(alpha=0.3)
            
            plt.subplot(1, 3, 2)
            plt.plot(episode_distances, alpha=0.3)
            if len(episode_distances) >= 100:
                plt.plot(np.convolve(episode_distances, np.ones(100)/100, mode='valid'), linewidth=2)
            plt.title('Episode Distances (ft)')
            plt.xlabel('Episode')
            plt.ylabel('Distance (ft)')
            plt.grid(alpha=0.3)
            
            plt.subplot(1, 3, 3)
            if len(launch_success_rate) >= 100:
                plt.plot(np.convolve(launch_success_rate, np.ones(100)/100, mode='valid'), linewidth=2)
            plt.title('Launch Success Rate')
            plt.xlabel('Episode')
            plt.ylabel('Success Rate')
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
        num_episodes=10000,
        steps_per_update=2048,
        save_every=100
    )
    
    print(f"\nTraining complete!")
    print(f"Final avg reward (last 100): {np.mean(rewards[-100:]):.2f}")
    print(f"Final avg distance (last 100): {np.mean(distances[-100:]):.1f}ft")

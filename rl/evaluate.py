# rl/evaluate.py
import sys
import numpy as np
import os
import torch

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'python')))
from sim.game import GameSim
from ppo_agent import PPOAgent, PPOConfig
from train import extract_state

def evaluate(model_path: str, num_episodes: int = 10, temperature: float = 0.5):
    """
    temperature: 0.0 = fully deterministic, 1.0 = full stochasticity
    0.3-0.5 usually works well for more robust evaluation
    """
    config = PPOConfig(state_dim=10)
    agent = PPOAgent(config)
    agent.load(model_path)
    
    distances = []
    launch_successes = []
    
    for ep in range(num_episodes):
        sim = GameSim()
        sim.jump()
        
        obs, _, _, info = sim.step(action=0)
        state = extract_state(obs, info, sim)
        
        done = False
        steps = 0
        launched = False
        
        while not done and steps < 5000:
            # Get action with temperature
            state_tensor = torch.FloatTensor(state).unsqueeze(0).to(agent.device)
            with torch.no_grad():
                logits, _ = agent.actor_critic(state_tensor)
                # Apply temperature
                probs = torch.softmax(logits / temperature, dim=-1)
                dist = torch.distributions.Categorical(probs)
                action = dist.sample().item()
            
            obs, reward, done, info = sim.step(action)
            
            if sim.jumping is False and not launched:
                launched = (sim.bullet is not None)
            
            state = extract_state(obs, info, sim)
            steps += 1
        
        distance = sim.bullet.x / 100.0 if sim.bullet else 0.0
        distances.append(distance)
        launch_successes.append(launched)
        print(f"Episode {ep+1}: {distance:.1f}ft (launched: {launched})")
    
    print(f"\nAverage distance: {np.mean(distances):.1f}ft")
    print(f"Best distance: {np.max(distances):.1f}ft")
    print(f"Launch success rate: {np.mean(launch_successes)*100:.0f}%")
    
    return distances


if __name__ == '__main__':
    import sys
    if len(sys.argv) < 2:
        print("Usage: python evaluate.py <model_path> [temperature]")
        sys.exit(1)
    
    temp = float(sys.argv[2]) if len(sys.argv) > 2 else 0.5
    evaluate(sys.argv[1], num_episodes=20, temperature=temp)

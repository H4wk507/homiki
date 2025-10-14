import torch
import torch.nn as nn
import torch.optim as optim
import numpy as np
from typing import Tuple, List
from dataclasses import dataclass


@dataclass
class PPOConfig:
    state_dim: int = 10
    action_dim: int = 2  # [glide_button, launch_button]
    hidden_dim: int = 256
    lr: float = 5e-4
    gamma: float = 0.99
    gae_lambda: float = 0.95
    clip_epsilon: float = 0.2
    entropy_coef: float = 0.05
    value_coef: float = 0.5
    max_grad_norm: float = 0.5
    ppo_epochs: int = 4
    batch_size: int = 64


class ActorCritic(nn.Module):
    def __init__(self, config: PPOConfig):
        super().__init__()
        self.config = config
        
        # Shared feature extractor
        self.features = nn.Sequential(
            nn.Linear(config.state_dim, config.hidden_dim),
            nn.ReLU(),
            nn.Linear(config.hidden_dim, config.hidden_dim),
            nn.ReLU(),
        )
        
        # Policy head (actor)
        self.policy = nn.Sequential(
            nn.Linear(config.hidden_dim, config.hidden_dim // 2),
            nn.ReLU(),
            nn.Linear(config.hidden_dim // 2, config.action_dim),
        )
        
        # Value head (critic)
        self.value = nn.Sequential(
            nn.Linear(config.hidden_dim, config.hidden_dim // 2),
            nn.ReLU(),
            nn.Linear(config.hidden_dim // 2, 1),
        )
        
    def forward(self, state: torch.Tensor) -> Tuple[torch.Tensor, torch.Tensor]:
        features = self.features(state)
        logits = self.policy(features)
        value = self.value(features)
        return logits, value
    
    def get_action(self, state: torch.Tensor, deterministic: bool = False):
        logits, value = self.forward(state)
        probs = torch.softmax(logits, dim=-1)
        
        if deterministic:
            action = torch.argmax(probs, dim=-1)
        else:
            dist = torch.distributions.Categorical(probs)
            action = dist.sample()
        
        log_prob = torch.log(probs.gather(-1, action.unsqueeze(-1))).squeeze(-1)
        entropy = -(probs * torch.log(probs + 1e-8)).sum(-1)
        
        return action, log_prob, entropy, value.squeeze(-1)


@dataclass
class RolloutBuffer:
    states: List[np.ndarray]
    actions: List[int]
    rewards: List[float]
    values: List[float]
    log_probs: List[float]
    dones: List[bool]
    
    def __init__(self):
        self.clear()
    
    def clear(self):
        self.states = []
        self.actions = []
        self.rewards = []
        self.values = []
        self.log_probs = []
        self.dones = []
    
    def add(self, state, action, reward, value, log_prob, done):
        self.states.append(state)
        self.actions.append(action)
        self.rewards.append(reward)
        self.values.append(value)
        self.log_probs.append(log_prob)
        self.dones.append(done)
    
    def get(self):
        return {
            'states': np.array(self.states),
            'actions': np.array(self.actions),
            'rewards': np.array(self.rewards),
            'values': np.array(self.values),
            'log_probs': np.array(self.log_probs),
            'dones': np.array(self.dones),
        }


class PPOAgent:
    def __init__(self, config: PPOConfig):
        self.config = config
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        
        self.actor_critic = ActorCritic(config).to(self.device)
        self.optimizer = optim.Adam(self.actor_critic.parameters(), lr=config.lr)
        
        self.buffer = RolloutBuffer()
        
    def select_action(self, state: np.ndarray, deterministic: bool = False):
        state_tensor = torch.FloatTensor(state).unsqueeze(0).to(self.device)
        
        with torch.no_grad():
            action, log_prob, entropy, value = self.actor_critic.get_action(
                state_tensor, deterministic
            )
        
        return action.item(), log_prob.item(), value.item()
    
    def compute_gae(self, rewards, values, dones, next_value):
        """Generalized Advantage Estimation"""
        advantages = np.zeros_like(rewards)
        last_gae = 0
        
        for t in reversed(range(len(rewards))):
            if t == len(rewards) - 1:
                next_value_t = next_value
                next_non_terminal = 1.0 - dones[t]
            else:
                next_value_t = values[t + 1]
                next_non_terminal = 1.0 - dones[t]
            
            delta = rewards[t] + self.config.gamma * next_value_t * next_non_terminal - values[t]
            last_gae = delta + self.config.gamma * self.config.gae_lambda * next_non_terminal * last_gae
            advantages[t] = last_gae
        
        returns = advantages + values
        return advantages, returns
    
    def update(self, next_state: np.ndarray):
        data = self.buffer.get()
        
        # Get next value for GAE
        next_state_tensor = torch.FloatTensor(next_state).unsqueeze(0).to(self.device)
        with torch.no_grad():
            _, next_value = self.actor_critic(next_state_tensor)
            next_value = next_value.item()
        
        # Compute advantages
        advantages, returns = self.compute_gae(
            data['rewards'], data['values'], data['dones'], next_value
        )
        
        # Normalize advantages
        advantages = (advantages - advantages.mean()) / (advantages.std() + 1e-8)
        
        # Convert to tensors
        states = torch.FloatTensor(data['states']).to(self.device)
        actions = torch.LongTensor(data['actions']).to(self.device)
        old_log_probs = torch.FloatTensor(data['log_probs']).to(self.device)
        returns = torch.FloatTensor(returns).to(self.device)
        advantages = torch.FloatTensor(advantages).to(self.device)
        
        # PPO update
        dataset_size = len(data['states'])
        indices = np.arange(dataset_size)
        
        for _ in range(self.config.ppo_epochs):
            np.random.shuffle(indices)
            
            for start in range(0, dataset_size, self.config.batch_size):
                end = start + self.config.batch_size
                batch_indices = indices[start:end]
                
                batch_states = states[batch_indices]
                batch_actions = actions[batch_indices]
                batch_old_log_probs = old_log_probs[batch_indices]
                batch_advantages = advantages[batch_indices]
                batch_returns = returns[batch_indices]
                
                # Forward pass
                logits, values = self.actor_critic(batch_states)
                probs = torch.softmax(logits, dim=-1)
                log_probs = torch.log(probs.gather(-1, batch_actions.unsqueeze(-1))).squeeze(-1)
                entropy = -(probs * torch.log(probs + 1e-8)).sum(-1).mean()
                
                # Policy loss (PPO clip)
                ratio = torch.exp(log_probs - batch_old_log_probs)
                surr1 = ratio * batch_advantages
                surr2 = torch.clamp(ratio, 1 - self.config.clip_epsilon, 
                                   1 + self.config.clip_epsilon) * batch_advantages
                policy_loss = -torch.min(surr1, surr2).mean()
                
                # Value loss
                value_loss = nn.MSELoss()(values.squeeze(-1), batch_returns)
                
                # Total loss
                loss = (policy_loss + 
                       self.config.value_coef * value_loss - 
                       self.config.entropy_coef * entropy)
                
                # Optimize
                self.optimizer.zero_grad()
                loss.backward()
                nn.utils.clip_grad_norm_(self.actor_critic.parameters(), 
                                        self.config.max_grad_norm)
                self.optimizer.step()
        
        self.buffer.clear()
        
        return {
            'policy_loss': policy_loss.item(),
            'value_loss': value_loss.item(),
            'entropy': entropy.item(),
        }
    
    def save(self, path: str):
        torch.save({
            'actor_critic': self.actor_critic.state_dict(),
            'optimizer': self.optimizer.state_dict(),
        }, path)
    
    def load(self, path: str):
        checkpoint = torch.load(path, map_location=self.device)
        self.actor_critic.load_state_dict(checkpoint['actor_critic'])
        self.optimizer.load_state_dict(checkpoint['optimizer'])

# Formal Verification of xTEE Secure Caching  Vulnerabilities


```
├── replay_attack.mcrl2         # DMA replay attack model (vulnerable)
├── timing_attack.mcrl2         # Context switch timing attack model (vulnerable)
├── fixed_replay_attack.mcrl2   # Secured DMA model with countermeasures
├── fixed_timing_attack.mcrl2   # Secured timing model with countermeasures
├── enclave_swap_dma.mcrl2         # Global xTEE secure caching model
├── Makefile                    # Automated verification and testing of Attacks and Fixs
└── README.md                   # This documentation
```
REPLAY_MODEL = replay_attack
TIMING_MODEL = timing_attack
LPS_FLAGS = -v --lin-method=regular2 --rewriter=jitty
LTS_FLAGS = -v --rewriter=jitty --cached
PBES_FLAGS = --formula=/dev/stdin
PBES2BOOL_FLAGS = 

.PHONY: all clean check-replay check-timing check-all build-replay build-timing

all: check-all

build-replay: $(REPLAY_MODEL).lts
build-timing: $(TIMING_MODEL).lts

# LTS generation
%.lps: %.mcrl2
	@echo "=== LPS generation for $< ==="
	mcrl22lps $(LPS_FLAGS) $< $@

%.lts: %.lps
	@echo "=== LTS generation for $< ==="
	lps2lts $(LTS_FLAGS) $< $@

check-replay: $(REPLAY_MODEL).lts
	@echo "==============================================================================="
	@echo "SANITY CHECKS FOR REPLAY ATTACK MODEL"
	@echo "==============================================================================="

	@echo "Check 1: Attacker can monitor DMA"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <attacker_monitor_dma(channel1)> true' | lts2pbes $(PBES_FLAGS) $(REPLAY_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 2: Attacker can read obsolete EFB"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <attacker_read_obsolete_efb(block0)> true' | lts2pbes $(PBES_FLAGS) $(REPLAY_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 3: Race condition detected during handover"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <dma_race_condition_detected> true' | lts2pbes $(PBES_FLAGS) $(REPLAY_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 4: DMA correctly receives handover signals"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <sync_handover_signal(channel1, channel2)> true' | lts2pbes $(PBES_FLAGS) $(REPLAY_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 5: Attacker receives replay attack results"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <sync_attack_result(block0, replayed)> true' | lts2pbes $(PBES_FLAGS) $(REPLAY_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 6: Attack is successful"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <attack_successful(block0)> true' | lts2pbes $(PBES_FLAGS) $(REPLAY_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 7: DMA can function normally before attack"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <dma_request(channel1, block0, ess, efbc)> true' | lts2pbes $(PBES_FLAGS) $(REPLAY_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 8: Normal DMA progression"
	@start_time=$$(date +%s.%3N); \
	echo '<dma_request(channel1, block0, ess, efbc)> <true*> <dma_progress(channel1, progress1)> true' | lts2pbes $(PBES_FLAGS) $(REPLAY_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 9: DMA can complete normal transfers"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <dma_progress(channel1, progress2)> <true*> <dma_complete(channel1, block0)> true' | lts2pbes $(PBES_FLAGS) $(REPLAY_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 10: Validation communications work"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <sync_validation_request(block0, secure)> <true*> <sync_validation_result(block0, valid)> true' | lts2pbes $(PBES_FLAGS) $(REPLAY_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

# Sanity checks for Timing Attack
check-timing: $(TIMING_MODEL).lts
	@echo "==============================================================================="
	@echo "SANITY CHECKS FOR TIMING ATTACK MODEL"
	@echo "==============================================================================="

	@echo "Check 1: Host OS can be compromised"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <host_os_compromise_detected> true' | lts2pbes $(PBES_FLAGS) $(TIMING_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 2: Attacker can saturate timers"
	@start_time=$$(date +%s.%3N); \
	echo '<host_os_compromise_detected> <true*> <attacker_saturate_timer> true' | lts2pbes $(PBES_FLAGS) $(TIMING_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 3: Timer saturation signals are communicated"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <sync_timer_saturation_signal> true' | lts2pbes $(PBES_FLAGS) $(TIMING_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 4: Attacker can manipulate access patterns"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <attacker_manipulate_pattern(manipulated)> true' | lts2pbes $(PBES_FLAGS) $(TIMING_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 5: Manipulated patterns are communicated to executor"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <sync_pattern_manipulation(manipulated)> true' | lts2pbes $(PBES_FLAGS) $(TIMING_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 6: Attacker can trigger memfault"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <attacker_trigger_memfault(block0)> true' | lts2pbes $(PBES_FLAGS) $(TIMING_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 7: Memfault triggers are communicated"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <sync_memfault_trigger(block0)> true' | lts2pbes $(PBES_FLAGS) $(TIMING_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 8: Timer contention is detected"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <timer_contention_detected> true' | lts2pbes $(PBES_FLAGS) $(TIMING_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 9: Context switches are delayed"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <context_switch_delayed> true' | lts2pbes $(PBES_FLAGS) $(TIMING_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 10: Attacker can request timer for validation"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <attacker_request_timer_validation> true' | lts2pbes $(PBES_FLAGS) $(TIMING_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 11: Timings are measured"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <attacker_measure_timing(3)> true' | lts2pbes $(PBES_FLAGS) $(TIMING_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 12: Timings are communicated to attacker"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <sync_timing_measurement(block0, 3)> true' | lts2pbes $(PBES_FLAGS) $(TIMING_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 13: Timing side channel leaks occur"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <timing_side_channel_leak(block0)> true' | lts2pbes $(PBES_FLAGS) $(TIMING_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 14: Attacker analyzes timings"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <attacker_analyze_timing(block0, 3)> true' | lts2pbes $(PBES_FLAGS) $(TIMING_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 15: Attacker can infer which EFB is requested"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <attack_infer_efb(block0)> true' | lts2pbes $(PBES_FLAGS) $(TIMING_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 16: Validator is sensitive to saturated timers"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <context_switch_delayed> true' | lts2pbes $(PBES_FLAGS) $(TIMING_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 17: Complete attack flow"
	@start_time=$$(date +%s.%3N); \
	echo '<host_os_compromise_detected> <true*> <attacker_saturate_timer> <true*> <attacker_manipulate_pattern(manipulated)> <true*> <attacker_trigger_memfault(block0)> <true*> <attack_infer_efb(block0)> true' | lts2pbes $(PBES_FLAGS) $(TIMING_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "Check 18: DMA functions normally during attack"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <dma_request(channel1, block0, ess, efbc)> <true*> <dma_complete(channel1, block0)> true' | lts2pbes $(PBES_FLAGS) $(TIMING_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

check-security: $(REPLAY_MODEL).lts $(TIMING_MODEL).lts
	@echo "==============================================================================="
	@echo "ATTACK VERIFICATION"
	@echo "==============================================================================="

	@echo "TIMING ATTACK"
	@start_time=$$(date +%s.%3N); \
	echo 'exists b: BlockID. <true*> <attacker_saturate_timer> <true*> <timing_side_channel_leak(b)> <true*> <attack_infer_efb(b)> true' | lts2pbes $(PBES_FLAGS) $(TIMING_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"

	@echo "REPLAY ATTACK"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <attacker_attempt_replay(block0,replayed)> <true*> <attack_successful(block0)> true' | lts2pbes $(PBES_FLAGS) $(REPLAY_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"
    
check-fix: fixed_$(REPLAY_MODEL).lts fixed_$(TIMING_MODEL).lts
	@echo "==============================================================================="
	@echo "COUNTERMEASURES VERIFICATION"
	@echo "==============================================================================="
	
	@echo "TIMING ATTACK"
	@start_time=$$(date +%s.%3N); \
	echo 'exists b: BlockID. <true*> <attacker_saturate_timer> <true*> <timing_side_channel_leak(b)> <true*> <attack_infer_efb(b)> true' | lts2pbes $(PBES_FLAGS) fixed_$(TIMING_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"
	
	@echo "REPLAY ATTACK"
	@start_time=$$(date +%s.%3N); \
	echo '<true*> <attacker_attempt_replay(block0,replayed)> <true*> <attack_successful(block0)> true' | lts2pbes $(PBES_FLAGS) fixed_$(REPLAY_MODEL).lts | pbes2bool; \
	end_time=$$(date +%s.%3N); \
	duration=$$(echo "$$end_time - $$start_time" | bc -l); \
	echo "  → Time taken: $$duration seconds"	

# Combined targets
check-all: check-replay check-timing check-security check-fix
	@echo "==============================================================================="
	@echo "ALL SANITY CHECKS COMPLETED"
	@echo "==============================================================================="

# Quick verification - only critical checks
check-quick: build-replay build-timing
	@echo "==============================================================================="
	@echo "QUICK SANITY CHECKS"
	@echo "==============================================================================="
	@echo "REPLAY ATTACK - Is attack successful?"
	@echo '<true*> <attack_successful(block0)> true' | lts2pbes $(PBES_FLAGS) $(REPLAY_MODEL).lts | pbes2bool

	@echo "TIMING ATTACK - Does attacker infer EFB?"
	@echo '<true*> <attack_infer_efb(block0)> true' | lts2pbes $(PBES_FLAGS) $(TIMING_MODEL).lts | pbes2bool

# Model statistics
stats: $(REPLAY_MODEL).lts $(TIMING_MODEL).lts
	@echo "==============================================================================="
	@echo "MODEL STATISTICS"
	@echo "==============================================================================="
	@echo "REPLAY ATTACK MODEL:"
	ltsinfo $(REPLAY_MODEL).lts
	@echo ""
	@echo "TIMING ATTACK MODEL:"
	ltsinfo $(TIMING_MODEL).lts

# Cleanup
clean:
	rm -f *.lps *.lts *.pbes
	@echo "Files cleaned"

# Help
help:
	@echo "==============================================================================="
	@echo "MAKEFILE FOR xTEE ATTACK MODELS"
	@echo "==============================================================================="
	@echo "Available targets:"
	@echo "  all              - Run all checks"
	@echo "  build-replay     - Build replay attack model"
	@echo "  build-timing     - Build timing attack model"
	@echo "  check-replay     - Sanity checks for replay attack"
	@echo "  check-timing     - Sanity checks for timing attack"
	@echo "  check-security   - Verify security properties"
	@echo "  check-quick      - Quick verification (only critical checks)"
	@echo "  stats            - Show model statistics"
	@echo "  clean            - Remove generated files"
	@echo "  help             - Show this message"
	@echo "==============================================================================="
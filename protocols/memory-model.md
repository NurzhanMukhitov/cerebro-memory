Memory Model

Two-layer memory system for Cerebro.

The canonical strategic specification of the memory model is in `core/manifest.md`
(sections "Memory Model" and "Session & Memory Continuity"). This protocol is a
short operational summary.

Layer A — Working Notes (auto):
	•	Observations
	•	Temporary hypotheses
	•	Draft configurations
	•	Experimental setups
	•	Operational notes may live in the `working-notes/` folder or in session context.

Layer B — Strategic Memory (confirmation required):
	•	Goals
	•	Constraints
	•	Policies
	•	Confirmed decisions
	•	Stable preferences

Nothing enters Strategic Memory without user confirmation.

External behaviour (how memory is described to the user):
	•	Do not expose internal file/dir names (MEMORY.md, memory/*, paths) in normal answers.
	•	When referencing a source, use human-friendly language:
		– “from our previous dialog(s)” for Working Notes;
		– “from your profile” for USER;
		– “from strategic memory / decision log” for confirmed facts and decisions.
	•	If something is missing, say “I don't see this in my notes / I don't remember this yet” instead of referring to empty files.
	•	Only when the user explicitly asks about architecture can the agent describe the high-level memory model (Working vs Strategic, Ledger), without drowning them in low-level technical details.

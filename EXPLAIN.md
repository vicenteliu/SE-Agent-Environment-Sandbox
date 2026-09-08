# The same chain, with no jargon

*For the person who has to approve this, fund it, or explain it to someone who will.*

**What is being built.** A safe room for a software agent to work in. The agent is given a task
and a set of tools, and it works for a long time — hours, sometimes days. The room has to keep it
from touching anything outside, and it has to let us stop the clock, look inside, go back to an
earlier moment, and try a different path.

**Why a room, and not just a computer.** Because the agent is allowed to run code it wrote itself.
Code you did not write can break things you did not expect. The room's walls are the whole point,
and there are four thicknesses of wall to choose from — thin and fast, up to a full separate
machine. Thicker walls cost more per hour. Choosing the thickness for each kind of task is a
decision a person makes once; the chain then applies it every time.

**Why "go back to an earlier moment" matters.** A long task that fails at hour six should not be
started again from zero. The room keeps saves — like a game — at several depths: what is on disk,
what is running, the whole machine, and (hardest) what is inside a graphics processor. Each depth
costs something different. From any save you can restore *twice* and let the two copies go
different ways. That is what turns one expensive attempt into a search.

**What "known-good" means.** A person declares which save was good. The system can suggest — it
watches for signs of trouble — but it does not get to grade its own work. The line between what
the machinery does and what a person decides is drawn on every page of this repository, on
purpose.

**What this repository is not.** It is not a product, not a report about a real company, and not
a claim that the author has run this at large scale. Every page says which parts were actually
run — on one machine — and which are written down for someone with more hardware to run. The
symbols 🔨 🧭 ⛔ are that honesty, in three characters.

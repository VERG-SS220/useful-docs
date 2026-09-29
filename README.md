# The automated installer of [CMPUnlocker](https://github.com/amoghmunikote/cmpunlocker) for Ubuntu

## The usage for the repo
This repo is primarily being used as a reference material for getting the CMP170HX unlocked, along with the `nvidia-smi` tooltip on identifying the key characteristics for your current card. ***CURRENTLY UNINTENDED FOR USAGE WITH OTHER CARDS!***

---

### What can be used to access the full 64 GiB (or 40 GiB) of RAM on CMP170HX?
* Modified [CMPUnlocker](https://github.com/amoghmunikote/cmpunlocker) to get the main files
* An `install.sh` file for a bootstrap for pretty much everything being used here. The AI community thanks [him](https://github.com/amoghmunikote) for his discovery in this topic.

## Tests on different distros

Currently, this installer has been fully tested on Ubuntu 22+, with Debian being currently deprecated due to unlocker installer difficulties.

| Bare metal | VM (primarily ESXi) |
|---|---|
| Works as intended, the unlocker gives the card 64 GiB of RAM | Works as intended, BAR1 patch removal code makes the card not deadlocked when getting loaded |

### Loicense

Oi, you got a loicense for that? Yes, mate: the [GNU General Public License v2.0](LICENSE), same as the upstream [CMPUnlocker](https://github.com/amoghmunikote/cmpunlocker).

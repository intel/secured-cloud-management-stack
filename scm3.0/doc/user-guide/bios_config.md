# Config SGX/TDX BIOS

## Enable TME, TDX

```text
Socket Configuration -> Processor Configuration -> TME, MK-TME, TDX -> Total Memory Encryption (TME) -> Enable
Socket Configuration -> Processor Configuration -> TME, MK-TME, TDX -> Total Memory Encryption (TME) Bypass -> Enable
Socket Configuration -> Processor Configuration -> TME, MK-TME, TDX -> Total Memory Encryption Multi-Tenant (TME-MT)  -> Enable
Socket Configuration -> Processor Configuration -> TME, MK-TME, TDX -> Memory Integrity -> Disable
Socket Configuration -> Processor Configuration -> TME, MK-TME, TDX -> TDX -> Enable
Socket Configuration -> Processor Configuration -> TME, MK-TME, TDX -> TDX Secure Arbitration Model Loader (SEAM Loader) -> Enable
Socket Configuration -> Processor Configuration -> TME, MK-TME, TDX -> TDX Key Split -> Enable
```


*NOTE: SGX/TDX will be visible only if TME is enabled.*

## Disable UMA-Based Clustering (Otherwise SGX will be grayed out)

```text
Socket Configuration -> Common RefCode Configuration -> UMA-Based Clustering -> Disable
```

## Enable SGX

```text
Socket Configuration -> Processor Configuration -> SW Guard Extensions(SGX) -> Enabled
Socket Configuration -> Processor Configuration -> SGX Package Info In-Band Access -> Enable
Socket Configuration -> Processor Configuration -> Enable/Disable SGX Auto MP Registration Agent -> Enable
```
## Attestation
```text
Socket Configuration -> Processor Configuration -> Processor Dfx Configuration -> SGX regristration server -> SBX
Platform Configuration -> ServerME Debug Configuration -> ServerME General Configuration -> Delayed Authentication Mode -> Disable
```


## Disable Patrol scrub (Only LCC & HCC):

```text
Socket Configuration -> Memory Configuration -> Memory RAS Configuration -> Patrol Scrub -> Disabled
```

## Disable Mirroring:

```text
Socket Configuration -> Memory Configuration -> Memory RAS Configuration -> Mirror Mode -> Disabled
```

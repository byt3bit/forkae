# ForkAE
This repository bundles all resources related to forkcipher, including articles, software and hardware implementations.

Website: https://www.esat.kuleuven.be/cosic/forkae/

**Elena Andreeva, Virginie Lallemand, Antoon Purnal, Reza Reyhanitabar, Arnab Roy, Damian Vizár**


## Implementations 
**Software**: ForkAE reference software implementation in C.

**Hardware**: Configurable hardware implementations of the ForkSkinny primitive. Among other things, we show ForkSkinny encryption can compute **both branches in parallel**, without too much increase in area.

- **Remark**: We would like to draw your attention to the following set of conventions. In our ASIACRYPT19 (AC19) paper, the forkcipher branches have been swapped
    when we presented the new forkcipher mode RPAEF, along with PAEF and SAEF that have been changed accordingly. More specifically:
    - In the *NIST LWC convention*, C1 is computed first, after which C0 is computed using the tweakey state after C1.
    - In the *AC19 convention*, C0 is computed first, after which C1 is computed using the tweakey state after C0.
    - Note that 'computed first' refers to the algorithmic description of the forkcipher, not to the actual implementation (where both can be computed in parallel).
- The encryption-only implementations in this repository can be used identically for both conventions. For the encryption-decryption configurations, the implementations in this repository adhere to the AC19 convention. 

### Implementations by other parties
Jowan Pittevils made [low-area hardware implementations](https://github.com/jowanpittevils/ForkSkinny-serial-implementations) of ForkSkinny (NIST LWC convention), exploring different execution paths through the forkcipher. He also made a nice [blog post](https://www.esat.kuleuven.be/cosic/forkae/forking-in-hardware-with-low-area-jowan-pittevils/) about his findings. Thanks, Jowan!

Arne Deprez made [optimized software implementations](https://github.com/ArneDeprez1/ForkAE-SW) of ForkAE (including ForkSkinny). Among other things, he shows that SIMD hardware (e.g., x86 AVX or ARM Neon) can leverage multiple sources of parallelism in ForkSkinny. Thanks, Arne!

## Articles
- Foundational forkcipher work (ASIACRYPT2019)
- Hardware implementation aspects (NIST LWC Workshop 2019)
- Second round specification for the NIST Lightweight Cryptography (LWC) Standardization

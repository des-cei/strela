# STRELA (STReaming ELAstic CGRA)

STRELA is a reconfigurable IP designed for accelerating compute-intensive tasks. It contains an elastic Coarse-Grained Reconfigurable Architecture (CGRA), 8 independent streaming memory nodes to load and store data, and a control unit.

<img src="block_diagrams/strela_bd_x-heep.png" width="300">

### CGRA overview
STRELA leverages a CGRA to provide high throughput and energy efficiency for domain-specific applications of the embedded domain. It is particularly suited for tasks requiring data parallelism and regular computation patterns, such as loops. It uses elastic logic (ie. valid/ready protocols) to support latency.

It is made up of Processing Elements (PE) with the following structure:

<img src="block_diagrams/pe_structure.png" width="200">

#### Functional Unit (FU)

The FUs are able to perform data- and control-oriented operations:
- *add*, *sub*, *mul*, *sub*, *shl*, *shra*, *shrl*, *AND*, *OR*, and *XOR* data-oriented operations.
- *branch*, *merge*, and *if/else* control-oriented operations.

<img src="block_diagrams/FU_microarchitecture.png" width="350">

#### FU inputs

<img src="block_diagrams/FU_input_output_microarchitecture.png" width="380">

#### PE inputs and outputs

<img src="block_diagrams/PE_input_output_microarchitecture.png" width="450">

### Compiling Framework

Coming soon!

### License
This project is licensed under the Solderpad Hardware License, Version 2.1, see [License](./LICENSE.md) for details. SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

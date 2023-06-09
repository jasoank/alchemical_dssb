Supplementary data and files for replicating "A Strategy for Improving Alchemical Method to Predict Protein Stability upon Conserving and Charge-Changing Mutation"

# Prerequisites

- GROMACS 2022 version or above, OpenMPI with CUDA-aware support is highly recommended
- pmx library 'develop' branch, please refer to https://github.com/deGrootLab/pmx/tree/develop
- AlphaFold2-structure prediction using ColabFold, please refer to: https://github.com/sokrypton/ColabFold
- Add the force field to the GROMACS library

    `$ export GMXLIB=/path/to/pmx/data/mutff'

# Directory Description

- /data
    -   /sequence: sequences for wild-type and all mutations in frataxin and p53 data sets
    -   /structure:
        - /mutant: mutant structures for conserving (tripepdtide) and charge-changing mutations (AF2)
            - /AF2: AlphaFold2 predicted structures
                - /folded_structure: default predicted structures in folded state for all mutation in frataxin and p53 data sets.
                - /unfolded_structure: unfolded structures for all mutation in frataxin and p53 data sets.
            - /tripeptide: generated glycine capped tripeptide for all 20 amino acids using Amber99SB-ILDN force field via Amber LeAP program
        - /wild_type: cleaned crystal structure (\*_protein.pdb), structure predicted by AlphaFold2 (\*_wild.pdb), and unfolded structure from high-temperature simulation (\*unfolded)

- /force_field: modified force field for mutations from pmx libraries
- /mdp: GROMACS .mdp configuratio files
    -  dssb_simulation: mdp files for double box-single system simulation
        - /eqA: mdp files for forward mutation
        - /eqB: mdp files for reverse mutation
    -  ht_simulation: mdp files for high temperature simulation
- /method:
    -   /dssb_simulation: 
        - /forward: `forward.sh`: bash script to run simulatio for forward mutation
        - /reverse: `reverse.sh`: bash script to run simulatio for reverse mutation      
    -   /ht_simulation: `ht_simulation.sh` , bash script to unfold structure through high-temperature simulation


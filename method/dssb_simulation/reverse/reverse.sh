mdp_dir = $1
wild_folded = $2
mutant_unfolded = $3

# separate the folded wild-type and unfolded mutant 3 nm away
pmx doublebox -f1 $wild_folded -f2 $mutant_unfolded -o init.pdb -r 3.0 --longest_axis
# convert to GROMACS structure
gmx_mpi pdb2gmx -f init.pdb -o init_gromacs.pdb -ff amber99sb-star-ildn-mut -water tip3p -ignh

# mutate both wild-type (chain A) and reverse (chain B)
pmx mutate -f init_gromacs.pdb -o mutant.pdb -ff  amber99sb-star-ildn-mut --keep_resid

# convert to GROMACS structure
gmx_mpi pdb2gmx -f mutant.pdb -o conf.pdb -ff  amber99sb-star-ildn-mut -water tip3p 

# generate hybrid topology
pmx gentop -p topol.top -o newtop.top -ff amber99sb-star-ildn-mut 

# simulation box
gmx_mpi editconf -f conf.pdb -o box.pdb -bt dodecahedron -d 1.0

# solvate in water
gmx_mpi solvate -cp box -cs spc216 -p newtop -o water.pdb

# load ions.mdp
gmx_mpi grompp -f /gs/hs0/tga-ishidalab/jason/new_mutation/dssb_mdp/ions.mdp -c water.pdb -p newtop.top -o genion.tpr

# add ions.mdp at 0.15 M concentration
echo "SOL" | gmx_mpi genion -s genion.tpr -p newtop.top -neutral -o ions.pdb -conc 0.15

# create new directory for storing equilibrium simulation files
mkdir equil_md | cd equil_md

# load energy minimization .mdp file for reverse mutation
gmx_mpi grompp -f $mdp_dir/eqB/em-B.mdp -c ../ions.pdb -p ../newtop.top -o enmin.tpr -maxwarn 1

# Run energy minimization, GROMACS initial 2022 version has bug when running enery minimization on GPU, latest version should have fixed this
gmx_mpi mdrun -s enmin.tpr -deffnm enmin -v -nb cpu

# load NVT minimization .mdp file for reverse mutation
gmx_mpi grompp -f $mdp_dir/eqB/nvt-B.mdp -r enmin.gro -c enmin.gro -p ../newtop.top -o nvt.tpr -maxwarn 3

# Perform NVT equilibriation
gmx_mpi mdrun -s nvt.tpr -deffnm nvt -v

# load NPT minimization .mdp file for reverse mutation
gmx_mpi grompp -f $mdp_dir/eqB/npt-B.mdp -r nvt.gro -c nvt.gro -p ../newtop.top -o npt.tpr -maxwarn 3

# Perform NPT equilibriation
gmx_mpi mdrun -s npt.tpr -deffnm npt -v

#  load the .mdp file for production MD of reverse mutation
gmx_mpi grompp -f $mdp_dir/eqB/md.mdp -c npt.gro -p ../newtop.top -o equil.tpr -maxwarn 4

# run production MD
gmx_mpi mdrun -s equil.tpr -deffnm equil -v

# create new directory for storing non-equilibrium simulation files
cd .. | mkdir nonequil_md | cd nonequil_md

# skip the first 2 ns simulation
echo "System" | gmx_mpi trjconv -f ../equil_md/equil.trr -s ../equil_md/equil.tpr -sep -b 2001 -o frame_.gro

# create 100 snapshots stored in frame_{snapshot number} directory
for i in $(seq 0 99); do n=$((i+1)); mkdir frame$n; mv frame_$i.gro frame$n/frame.gro; done

# perform non-equilibirum transition simulation for all snapshots
for i in $( seq 1 100 ); do
  cd frame$i
  gmx_mpi grompp -f $mdp_dir/eqB/morph.mdp -c frame.gro -p ../../newtop.top -o nonequil.tpr -maxwarn 4
  gmx_mpi mdrun -s nonequil.tpr -deffnm nonequil -dhdl dgdl.xvg -v
  cd ../
done
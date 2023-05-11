for file in *; do 
mkdir ${file%.*} &&
mv -v $file ${file%.*}
done

for d in * ; do
    echo "$d"

cd $d

gmx_mpi pdb2gmx -f $d".pdb" -o $d".gro" -water spce -ff oplsaa -ignh

# # gmx_mpi pdb2gmx -f $d"_clean.pdb" -o $d".gro" -water spce -ff amber03

gmx_mpi editconf -f $d".gro" -o $d"_newbox.gro" -c -d 1.0 -bt dodecahedron

gmx_mpi solvate -cp $d"_newbox.gro" -cs spc216.gro -o $d"_solv.gro" -p topol.top
 
gmx_mpi grompp -f /gs/hs0/tga-ishidalab/jason/new_mutation/mdp/ions.mdp -c $d"_solv.gro" -p topol.top -o ions.tpr -maxwarn 1

yes SOL | gmx_mpi genion -s ions.tpr -o $d"_solv_ions.gro" -p topol.top -pname NA -nname CL -neutral

gmx_mpi grompp -f /gs/hs0/tga-ishidalab/jason/new_mutation/mdp/minim.mdp -c $d"_solv_ions.gro" -p topol.top -o em.tpr

gmx_mpi mdrun -v -deffnm em -nb cpu

printf "10 0" | gmx_mpi energy -f em.edr -o $d"_potential.xvg"  

gmx_mpi grompp -f /gs/hs0/tga-ishidalab/jason/new_mutation/mdp/nvt.mdp -c em.gro -r em.gro -p topol.top -o nvt.tpr

gmx_mpi mdrun -deffnm nvt

printf "16 0" | gmx_mpi energy -f nvt.edr -o $d"_temperature.xvg"  

gmx_mpi grompp -f /gs/hs0/tga-ishidalab/jason/new_mutation/mdp/npt.mdp -c nvt.gro -r nvt.gro -t nvt.cpt -p topol.top -o npt.tpr

gmx_mpi mdrun -deffnm npt

gmx_mpi grompp -f /gs/hs0/tga-ishidalab/jason/new_mutation/mdp/md.mdp -c npt.gro -t npt.cpt -p topol.top -o $d".tpr"

printf "18 0" | gmx_mpi energy -f npt.edr -o $d"_pressure.xvg"

gmx_mpi mdrun -deffnm $d


printf 'Protein Protein' | gmx_mpi trjconv -s $d".tpr" -f $d".xtc" -o $d"_noPBC.xtc" -pbc mol -center -ur compact 

printf 'Protein Protein' | gmx_mpi trjconv -s $d".tpr" -f $d"_noPBC.xtc" -o $d"_noPBC_fit.xtc" -fit rot+trans

printf 'Protein Protein' | gmx_mpi trjconv -f $d"_noPBC_fit.xtc" -s $d".tpr" -o $d"_unfolded.pdb" -dump 1000

printf 'Protein' | gmx_mpi convert-tpr -s $d".tpr" -o $d"_protein.tpr"

cd /gs/hs0/tga-ishidalab/jason/new_mutation/forward/

done
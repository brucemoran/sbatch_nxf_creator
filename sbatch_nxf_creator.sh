#! bash -l

##shell to prepare SBATCH file for running in SLURM
YAML=$1
##read YAML
##array of YAML heads
declare -a YML_HEAD=($(grep ":" ${YAML} | grep -v "/" | perl -ane 'print "$F[0] ";') )
YML_HEADS=$(( ${#YML_HEAD[@]} - 1 ))

##iterate and parse hyphens
function yml_parse {
  i=$1; j=$2
  THIS=$(( $(grep -n ${YML_HEAD[$i]} ${YAML} | cut -d ":" -f -1) + 1 ))
  TEST=$(sed -n ${THIS}p ${YAML})

  ##if TEST has space-hyphen-space, it's part of a list
  if [[ "$TEST" =~ " - " ]]; then
    NEXT=$(( $(grep -n ${YML_HEAD[$j]} ${YAML} | cut -d ":" -f -1) - 1 ))
    echo $(sed -n ${THIS},${NEXT}p ${YAML} | sed 's/ - //g')
  else
    THIS=$(grep -n ${YML_HEAD[$i]} ${YAML} | cut -d ":" -f -1)
    echo $(sed -n ${THIS}p ${YAML} | sed 's/ - //g' | cut -d ":" -f 2-)
  fi
}

##no array of arrays in bash...
NAMES=($(yml_parse 0 1 | sed 's/"//g' ))
PIPELINES=($(yml_parse 1 2))
VERS_NXF=($(yml_parse 2 3 | sed 's/"//g'))
CONF_NXF=($(yml_parse 3 4 | sed 's/"//g'))
BASE_NXF=($(yml_parse 4 5 | sed 's/"//g'))


##sub BASE_NXF in OUTDIR
BASE_NXF=${BASE_NXF[@]}
OUTDIR=$(echo "{BASE_NXF}/{NAME}" | sed "s#{BASE_NXF}#${BASE_NXF}#")

##template BATCH file
echo -e '#!/bin/bash -l' > $BASE_NXF/.template.sbatch
echo -e '#SBATCH --job-name={NAME}' >> $BASE_NXF/.template.sbatch
echo -e '#SBATCH --output={BASE_NXF}/{NAME}/{NAME}.log' >> $BASE_NXF/.template.sbatch
echo -e '#SBATCH --ntasks=1' >> $BASE_NXF/.template.sbatch
echo -e '#SBATCH --time 120:00:00' >> $BASE_NXF/.template.sbatch
echo -e '#SBATCH --cpus-per-task=1' >> $BASE_NXF/.template.sbatch
echo -e '#SBATCH --tasks-per-node=1' >> $BASE_NXF/.template.sbatch
echo -e 'module load nextflow/{VERS_NXF} singularity/3.5.2' >> $BASE_NXF/.template.sbatch

##create another hidden conf for the sbatch to specify outdir and launchdir
for NAME in ${NAMES[@]}; do
  echo "Working on $NAME"

  ##output directory
  OUTD=$(echo $OUTDIR | sed "s#{NAME}#${NAME}#")
  mkdir -p $OUTD

  ##pipeline info config
  echo "params.outDir = \"$OUTD\"" > $OUTD/.${NAME}.nextflow.config
  echo "workflow.workDir = \"\${params.outDir}/work\"" >> $OUTD/.${NAME}.nextflow.config
  for x in dag report timeline trace; do
   echo -e "$x {\n\tenabled = true\n\tfile = \"\${params.outDir}/pipeline_info/$x.html\"\n}" >> $OUTD/.${NAME}.nextflow.config
  done

  ##cat other configs into above
  if [[ $CONF != "" ]]; then
    CONF=$(for i in `seq 0 $(( ${#CONF_NXF[@]} - 1 ))`; do
      cat ${CONF_NXF[$i]} >> $OUTD/.${NAME}.nextflow.config
    done)
  fi

  ##make PIPELINE
  echo ${PIPELINES[@]} | \
  sed 's/nextflow run/run/g' | \
  while read LINE; do
    echo "srun nextflow -log $OUTD/.nextflow.log "$LINE" -c $OUTD/.${NAME}.nextflow.config -w $OUTD/work -with-mpi"
  done > .pls
  cat $BASE_NXF/.template.sbatch .pls > $OUTD/.template.sbatch
  rm .pls

  ##sed template
  sed "s#{NAME}#${NAME}#g" $OUTD/.template.sbatch | \
  sed "s#{VERS_NXF}#${VERS_NXF}#g" | \
  sed "s#{BASE_NXF}#${BASE_NXF}#g" > $OUTD/${NAME}.sbatch
done

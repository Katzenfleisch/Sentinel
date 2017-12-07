mod_name="Sentinel"
base_dir="/media/NS2"
# if [ $# -eq 1 ]
# then
    # rm -vrf $base_dir${mod_name}/*
    # rm -rf $base_dir${mod_name}_production/output/
    # mkdir -p $base_dir${mod_name}_production/output/
    # echo "Remove done"
    ##
    rsync --delete --progress -vcr ./* $base_dir/${mod_name}_production/output/ --exclude=.git/ --exclude=update_other_dir.sh

    cp .modinfo $base_dir/${mod_name}_production/output/
# fi

rsync --delete --progress -vcr ../${mod_name}/ $base_dir/${mod_name}/
echo "Copy done"

# if [ $# -eq 1 ]
# then
#     rm -vrf $base_dir${mod_name}/*
#     echo "Remove done"
# fi
# cp -vru ../${mod_name}/ $base_dir
# echo "Copy done"

#!/bin/bash -xe

log_dir_parent=${TEST_DIR}/project/anomaly

mkdir -m 777 -p ${log_dir_parent}

id=$(ls "${log_dir_parent}" | wc -l)

# save current logs
log_id=id_$(printf "%06d" "$id")_$(date +"%Y%m%d_%Hh%Mm%Ss")
log_content_dir=${log_dir_parent}/content
log_report_dir=${log_dir_parent}/report
mkdir -m 777 -p $log_content_dir
mkdir -m 777 -p $log_report_dir

# log report (server log)
tail -n 2000 ${log_dir_parent}/../logs/output.log 2>&1 | tee ${log_report_dir}/${log_id}

#tail -n 200 $log_dir/griffin.log > $log_dir/griffin.log

# save the last test case
input_file="${log_dir_parent}/../logs/output.log"

# Find the last occurrence of "[GRIFFIN DEBUG][TESTCASE BEGIN]"
begin_line=$(grep -n "\[GRIFFIN DEBUG\]\[TESTCASE BEGIN\]" $input_file | tail -n 1 | cut -d ":" -f 1)

# Find the last occurrence of "[GRIFFIN DEBUG][TESTCASE END]"
end_line=$(grep -n "\[GRIFFIN DEBUG\]\[TESTCASE END\]" $input_file | tail -n 1 | cut -d ":" -f 1)

(
    # Check if both lines were found
    if [ -z "$begin_line" ] || [ -z "$end_line" ]; then
        echo "Error: could not find begin or end line."
        tail -n 1000 $input_file
    else
        # Extract the lines between begin and end, and remove the debug lines
        sed -n "${begin_line},${end_line}p" $input_file | sed -e '1d' -e '$d' | sed -e 's/\[GRIFFIN DEBUG\]\[TESTCASE BEGIN\]//' -e 's/\[GRIFFIN DEBUG\]\[TESTCASE END\]//'
    fi
) >> ${log_content_dir}/${log_id}

# log (just for debugging)
xz -T0 "${log_dir_parent}/../logs/output.log" -o "${log_dir_parent}/../logs/output_${log_id}.log.xz"

# clean existing logs
cat /dev/null > ${log_dir_parent}/../logs/output.log

# scrip_dir=`dirname $0`
# echo $scrip_dir
#$scrip_dir/analysis_logs.sh <${log_report_dir}/${log_id}  2>&1 |tee ${log_content_dir}/${log_id}

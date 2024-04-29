#!/bin/bash
FILES=$(curl http://www.phrack.org/archives/tgz/ | egrep -o ">phrack(.*).tar.gz" | cut -c 2-)

FILES_DOWNLOADED=()

stitch_issues() {
    # list existing
    for f in * ; do # [ -d "$f" ] && echo $f is indeed a folder ; done
        if [ -d "$f" ] && [[ "$f" =~ ^phrack[0-9]+$ ]]; then
            # stitch
            if [ -f "${f}.txt" ] && [[ $(stat -c%s "${f}.txt") -ne 0 ]]; then
                echo "${f}.txt already exists, and it not empty. Skipping this issue"
                continue
            fi

            touch "${f}.txt"
            DIRBYTES=0
            for text_file in "$f"/*; do
                echo "FOUND ${text_file}"
                if [ -f "${text_file}" ] && [[ "${text_file}" =~ [0-9]+.txt$ ]]; then
                    DIRBYTES=$(( DIRBYTES + $(stat -c%s "$text_file") ))
                    echo "${text_file} will be appended to ${f}.txt"
                    cat "${text_file}" >> "${f}.txt"
                    echo "Written ${DIRBYTES} >> ${f}.txt"
                else
                    echo "${text_file} did not match ^[0-9]+.txt$"
                fi
            done

            if [ -f "${f}.txt" ] && [[ $(stat -c%s "${f}.txt") -eq $DIRBYTES ]]; then
                echo "${f}.txt bytes matches ${DIRBYTES}! Deleting origin..."
                rm -r $f
            else
                echo "${f}.txt is $(stat -c%s "${f}.txt") bytes. Expecing ${DIRBYTES}."
            fi
        fi
    done
}

echo "READING REMOTE..."
for file_name in $FILES; do
    if [[ ! "$file_name" =~ ^phrack[0-9]+.tar.gz$ ]]; then
        echo "Invalid filename. Skipping."
        continue
    fi
    FILEARR+=($file_name)
    UNZIP_DIR=$(echo "$file_name" | cut -d . -f 1)
    if [ ! -f ./${file_name} ] && [ ! -d ${UNZIP_DIR} ]; then
        echo "FILE ${file_name} NOT FOUND LOCALLY. DOWNLOADING..."
        curl -O "http://www.phrack.org/archives/tgz/${file_name}"
        if [ ! -d ${UNZIP_DIR} ]; then
            mkdir ${UNZIP_DIR}
        else 
            echo "${UNZIP_DIR} should already exist"
        fi
        tar -xzvf ${file_name} -C ${UNZIP_DIR}
        FILES_DOWNLOADED+=($file_name)
        # remove tar
        if [ -d ${UNZIP_DIR} ]; then
            echo "removing ${file_name}"
            rm ${file_name}
        fi
    fi
done

for new_file in "${FILES_DOWNLOADED[@]}"; do
    echo "${new_file} NEW ISSUE!"
done

stitch_issues

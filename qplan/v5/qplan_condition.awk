#!/usr/bin/gawk -f

BEGIN {
        FS = "\t";
}

$0 == "=====Work" {
        type = "WORK"
        start_record = NR + 3
}

$0 == "=====Staff" {
        type = "STAFF"
        start_record = NR + 3
        track_heading_row = NR + 2
}

type == "WORK" && NR >= start_record {
        work_items[num_work_items++] = \
             sprintf("%d\t%s\tNative:%s,Web:%s,Apps:%s\t"\
               "ProdTriage:%s,EngTriage:%s,Triage:%s\ttrack:%s,Description:%s,"\
                                "RequestingTeam:%s,Dependencies:%s,Notes:%s",\
             num_work_items, $5, $10, $11, $12,\
             $1, $2, $3, $4, $6,\
             $7, $8, $13)
}


# Store track titles
type == "STAFF" && NR == track_heading_row {
        for (i = 2; i <= NF; i++) {
                if ($i == "")
                        break
                track_titles[i] = $i
        }
}

# Set skill type
type == "STAFF" && $1 != "" {
        skill = $1;
        if (skill == "Server")
                skill = "Apps";
}

# Store assignments
type == "STAFF" && NR >= start_record {
        tmp = IGNORECASE
        IGNORECASE = 1

        for (i = 2; i <= NF; i++) {
                # If the track title is blank, we've gone too far to the right
                if (track_titles[i] == "")
                        break

                # If we see numbers, we've gone too far down
                if ($i ~ /^[0-9]+/)
                        break

                # If someone has a start or end in their name, we'll assume
                # they'll only be here part of the quarter.
                if ($i ~ /start/ || $i ~ /end/)
                        factor = 0.3
                else
                        factor = 1

                # If we have a name, and it's not a hole, then make the
                # assignment
                if ($i && $i !~ /Hole/)
                        assignments[num_assignments++] = \
                                                  sprintf("%d\t%s\t%s:%.1f\t%s",
                                                     num_assignments, $i, skill,
                                                     factor,
                                                     track_titles[i])
        }

        IGNORECASE = tmp
}


END {
        # Print work items
        print("=====Work")
        print("ID\tName\tEstimate\tTriage\tTags");
        print("-----");
        for (i = 1; i < num_work_items; i++)
                print work_items[i];

        # Print staff items
        print("=====Staff")
        printf("ID\tName\tSkills\tTags\n");
        printf("-----\n");
        for (i = 1; i < num_assignments; i++)
                print assignments[i]
}

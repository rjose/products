function WorkCtrl($scope, $http) {
        $scope.work_data = [];
        $scope.tracks = ["All", "Track 1", "Track 2"];
        $scope.selected_track = "All";
        $scope.triage = 1.5;
        $scope.staffing_stats = {
                skills: ['Apps', 'Native', 'Web'],
                required: {'Apps': 11, 'Native': 2, 'Web': 2},
                available: {'Apps': 4, 'Native': 3, 'Web': 2},
                net_left: {'Apps': -7, 'Native': 1, 'Web': 0},
                feasible_line: 2
        };

        $scope.work_items = [
                {rank: 5, triage: 1, track: 'Track Alpha', name: 'Something to do', estimate: 'Apps: Q, Native: 3S, Web: M'},
                {rank: 8, triage: 1, track: 'Track Alpha', name: 'Something to do', estimate: 'Apps: Q, Native: 3S, Web: M'},
                {rank: 15, triage: 1.5, track: 'Track Alpha', name: 'Something to do', estimate: 'Apps: Q, Native: 3S, Web: M'},
                {rank: 22, triage: 2, track: 'Track Alpha', name: 'Something to do', estimate: 'Apps: Q, Native: 3S, Web: M'}
        ];

        $scope.update = function() {
                console.log("Update: " + $scope.triage + " " + $scope.selected_track);
        };

        $scope.selectTrack = function(track) {
                angular.forEach($scope.tracks, function(t) {
                        if (t == track) {
                                $scope.selected_track = t;
                                $scope.update();
                        }
                });
        };


        // Load data to render
        $http.get('/app/web/work').then(
                        function(res) {
                                console.dir(res);
                                $scope.work_data = res.data
                        },
                        function(res) {
                                console.log("Ugh.");
                                console.dir(res);
                        });

        // A helper function to convert a tags hash to a string
        $scope.tags_to_string = function(tags) {
                var keys = [];
                for (var key in tags) {
                        keys.push(key)
                }
                keys.sort()

                var result = "";
                for (var i in keys) {
                        var key = keys[i];
                        if (tags[key]) {
                                result = result + key + ": " + tags[key] + ", "
                        }
                }
                // Get rid of trailing comma
                if (result.length >= 2) {
                        result = result.slice(0, result.length-2);
                }
                return result;
        };
}


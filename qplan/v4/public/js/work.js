function WorkCtrl($scope, $http) {
        $scope.work_data = [];

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


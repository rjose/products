function TracksCtrl($scope, $http) {
        $http.get('/app/web/tracks').then(
                        function(res) {
                                console.dir(res);
                                $scope.data = res.data
                        },
                        function(res) {
                                console.log("Ugh.");
                                console.dir(res);
                        });
}

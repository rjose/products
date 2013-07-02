function StaffCtrl($scope, $http) {
        $scope.staff_data = [];

        // Load data to render
        $http.get('/app/web/staff').then(
                        function(res) {
                                console.dir(res);
                                $scope.staff_data = res.data
                        },
                        function(res) {
                                console.log("Ugh.");
                                console.dir(res);
                        });
}

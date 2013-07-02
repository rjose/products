function StaffCtrl($scope, $http) {
        $scope.skills = [];

        // Load data to render
        $http.get('/app/web/staff').then(
                        function(res) {
                                console.dir(res);
                                $scope.skills = res.data.skills;
                        },
                        function(res) {
                                console.log("Ugh.");
                                console.dir(res);
                        });


        $scope.loadStaffData = function() {
                console.log("TODO: Load staff data");
        };
}

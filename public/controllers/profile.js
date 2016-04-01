'use strict';
var app = angular.module('mainApp');
app.controller('ProfileController', ['$scope', '$location', '$http', 'authenticationService',
    function ($scope, $location, $http, authenticationService) {

    // Get memberships
    $scope.fetch = function () {
        $http({
            method: 'POST',
            url: '/user/memberships',
            headers: {
                'Authorization': authenticationService.getUserToken()
            },
            data: null

        }).success(function (data, status, headers, config) {
            console.log(data);
            $scope.memberships = data;

        }).error(function (data, status, headers, config) {
            console.log("Error")
        });
    };
    $scope.fetch();
}]);

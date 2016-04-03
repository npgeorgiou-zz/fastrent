'use strict';
var app = angular.module('mainApp');
app.controller('ProfileController', ['$scope', '$location', '$http', '$compile', 'authenticationService',
    function ($scope, $location, $http, $compile, authenticationService) {
        $scope.showModal = false;

        $scope.hide = function(){
            $scope.showModal = false;
        }

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

        // Get memberships
        $scope.deleteProfile = function () {
            $http({
                method: 'POST',
                url: '/user/delete',
                headers: {
                    'Authorization': authenticationService.getUserToken()
                },
                data: null

            }).success(function (data, status, headers, config) {
                console.log(data);
                $scope.hide();
                // Delete token and settings
                authenticationService.logOutUser();
                $location.path('/goodbye');

            }).error(function (data, status, headers, config) {
                $scope.hide();
                console.log("Error")
            });
        };
    }]);

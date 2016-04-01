'use strict';
var app = angular.module('mainApp');
app.controller('RequestNewPasswordController', ['$scope', '$rootScope', '$location', '$http', 'authenticationService',
    function ($scope, $rootScope, $location, $http, authenticationService) {

        $scope.requestNewPassword = function () {
            $http({
                method: 'POST',
                url: '/user/password-request',
                data: {
                    email: $scope.email
                }

            }).success(function (data, status, headers, config) {
                console.log(data);
                $location.path('/password-link-sent');
            }).error(function (data, status, headers, config) {
                console.log('Error')
            });
        };

    }]);
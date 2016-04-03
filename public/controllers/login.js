'use strict';
var app = angular.module('mainApp');
app.controller('LoginController', ['$scope', '$rootScope', '$location', '$http', 'authenticationService', 'settingsService',
    function ($scope, $rootScope, $location, $http, authenticationService, settingsService) {

        $scope.goToRequestNewPasswordView = function () {
            $location.path('/request-new-password');
        }

        $scope.login = function () {
            $http({
                method: 'POST',
                url: '/user/login',
                data: {
                    email:    $scope.email,
                    password: $scope.password
                }

            }).success(function (data, status, headers, config) {
                console.log(data)
                console.log(data.token)
                console.log(data.settings)
                // Save token
                authenticationService.logInUser(data.token);

                // Save settings
                if (data.settings !== null) {
                    settingsService.setSettings(data.settings);
                }

                // Redirect to results
                $location.path('/results');
            }).error(function (data, status, headers, config) {
                switch (status) {
                    case 409:
                        // No user with these credentials found
                        $scope.feedback = data
                        break;
                    default:
                        break;
                }
            });
        };

    }]);
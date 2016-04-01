'use strict';
var app = angular.module('mainApp');
app.controller('UserExistsController', ['$scope', '$location', '$http', 'authenticationService',
    function ($scope, $location, $http, authenticationService) {

        $scope.goToRequestNewPasswordView = function () {
            $location.path('/request-new-password');
        }

}]);

'use strict';
var app = angular.module('mainApp');
app.controller('PasswordLinkInvalidController', ['$scope', '$location', 'settingsService', function ($scope, $location, settingsService) {

    $scope.goToRequestNewPasswordView = function () {
        $location.path('/request-new-password');
    }

}]);

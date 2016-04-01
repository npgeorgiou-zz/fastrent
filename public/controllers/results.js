'use strict';
var app = angular.module('mainApp');

app.controller('ResultsController', ['$scope', '$location', '$http', 'settingsService', 'authenticationService', 'intervalService',
    function ($scope, $location, $http, settingsService, authenticationService, intervalService) {
        $scope.openTab = function (url) {
            // Check if user is logged in
           if (url === 'hidden') {
               $location.path('/register');
           } else {
               window.open(url, '_blank');
           }
        };

        var busy = false
        var reachedEnd = false;
        // Make call
        $scope.fetch = function () {
            if (busy) return;
            if (reachedEnd) return;

            busy = true;

            var from = null;
            if ($scope.ads) {
                from = $scope.ads.last().posted
            } else {
                from = 0;
            }
            $http({
                method: 'POST',
                url: '/fetch',
                headers: {
                    'Authorization': authenticationService.getUserToken()
                },
                data: {
                    site: settingsService.getSettings().site,
                    region: settingsService.getSettings().region,
                    type: settingsService.getSettings().type,
                    minRent: settingsService.getSettings().minRent,
                    maxRent: settingsService.getSettings().maxRent,
                    from:    from
                }

            }).success(function (data, status, headers, config) {
                console.log(data);

                if (data.length === 0) {
                    reachedEnd = true;
                    return;
                }

                var timestampNow = Math.floor(Date.now() / 1000);
                for (var i = 0; i < data.length; ++i) {
                    data[i].postedAgo = timeDifference(timestampNow, data[i].posted)
                }

                if ($scope.ads) {
                    Array.prototype.push.apply($scope.ads, data);
                } else {
                    $scope.ads = data;
                }

                busy = false;

            }).error(function (data, status, headers, config) {
                console.log("Error");
                switch (status) {
                    case 404:
                        // No user with this token found
                        authenticationService.logOutUser();
                        $location.path('/confused');
                        break;
                    default:
                        break;
                }
            });
        };

        $scope.fetchNew = function () {

            var from = null;
            if ($scope.ads) {
                from = $scope.ads.first().posted
            } else {
                from = 0;
            }
            $http({
                method: 'POST',
                url: '/fetch-new',
                headers: {
                    'Authorization': authenticationService.getUserToken()
                },
                data: {
                    site: settingsService.getSettings().site,
                    region: settingsService.getSettings().region,
                    type: settingsService.getSettings().type,
                    minRent: settingsService.getSettings().minRent,
                    maxRent: settingsService.getSettings().maxRent,
                    from:    from
                }

            }).success(function (data, status, headers, config) {
                console.log(data);
                var timestampNow = Math.floor(Date.now() / 1000);
                for (var i = 0; i < data.length; ++i) {
                    data[i].postedAgo = timeDifference(timestampNow, data[i].posted)
                }

                if ($scope.ads) {
                    $scope.ads = data.concat($scope.ads);
                } else {
                    $scope.ads = data;
                }

            }).error(function (data, status, headers, config) {
                console.log("Error");
                switch (status) {
                    case 404:
                        // No user with this token found
                        authenticationService.logOutUser();
                        $location.path('/confused');
                        break;
                    default:
                        break;
                }
            });
        };


        // If the interval is not already set, and the user is authenticated, keep fetching
        if (!intervalService.isIntervalSet() && authenticationService.isUserLoggedIn()) {
            var fetchInterval = setInterval(
                function () {
                    $scope.fetchNew();
                },
                1000 * 60
            );
            intervalService.setInterval(fetchInterval);
        }

        function timeDifference(timestamp1, timestamp2) {
            var difference = timestamp1 - timestamp2;

            var daysDifference = Math.floor(difference / (60 * 60 * 24));
            if (daysDifference === 1) {
                return daysDifference + ' day ago';
            }
            if (daysDifference > 1) {
                return daysDifference + ' days ago';
            }

            //difference -= daysDifference * 60 * 60 * 24
            var hoursDifference = Math.floor(difference / (60 * 60));
            if (hoursDifference === 1) {
                return hoursDifference + ' hour ago';
            }
            if (hoursDifference >= 1) {
                return hoursDifference + ' hours ago';
            }

            //difference -= hoursDifference * 60 * 60
            var minutesDifference = Math.floor(difference / 60);
            if (minutesDifference === 1) {
                return minutesDifference + ' minute ago';
            }

            return minutesDifference + ' minutes ago';
        }
    }]);

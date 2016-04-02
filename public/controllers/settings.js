'use strict';
var app = angular.module('mainApp');
app.controller('SettingsController', ['$scope', '$location', '$http', '$q', 'settingsService', 'authenticationService',
    function ($scope, $location, $http, $q, settingsService, authenticationService) {

        // Get user settings from service
        var settings = settingsService.getSettings();
        console.log(settings);

        // Slider with draggable range
        // https://jsfiddle.net/ValentinH/954eve2L/
        $scope.slider = {
            minValue: settings.minRent,
            maxValue: settings.maxRent,
            options: {
                ceil: 30000,
                step: 1000,
                floor: 0,
                draggableRange: true,
                translate: function (value) {
                    return value + ' .kr';
                }
            }
        };

        // Sites
        $scope.sites = ['Boligportal', 'Dba', 'Boligbasen'];
        $scope.selectedSites = settings.site;

        // Toggle selection for a given site by name
        $scope.toggleSiteSelection = function toggleSiteSelection(siteName) {
            toggleSelection(siteName, $scope.selectedSites);
        };

        // Regions
        $scope.regions = [
            'Hovedstaden',
            'Sjælland',
            'Syddanmark',
            'Nordjylland',
            'Midtjylland'
        ];
        $scope.selectedRegions = settings.region;
        $scope.toggleRegionSelection = function toggleRegionSelection(regionName) {
            toggleSelection(regionName, $scope.selectedRegions);
        };

        // Types
        $scope.types = [
            'Apartment',
            'House',
            'Room'
        ];
        $scope.selectedTypes = settings.type;
        $scope.toggleTypeSelection = function toggleTypeSelection(typeName) {
            toggleSelection(typeName, $scope.selectedTypes);
        };

        // Email
        $scope.frequencies = [
            {
                name:"Don't send me emails",
                mins: 0
            },
            {
                name:'Send me every 30 minutes',
                mins: 30
            },
            {
                name:'Send me every 1 hour',
                mins: 60
            },
            {
                name:'Send me every 2 hours',
                mins: 120
            },
            {
                name:'Send me every 4 hours',
                mins: 240
            },
            {
                name:'Once a day, at 20:00',
                mins: 60 * 24
            }
        ];

        $scope.selectedFrequency = settings.emailFrequency;

        // Toggle selection for a given site by name
        $scope.toggleEmailFrequencySelection = function toggleEmailFrequencySelection(mins) {
            $scope.selectedFrequency = mins
            console.log($scope.selectedFrequency);
        };

        function toggleSelection(strElement, array) {
            var index = array.indexOf(strElement);

            // Is currently selected
            if (index > -1) {
                array.splice(index, 1);
            }

            // Is newly selected
            else {
                array.push(strElement);
            }
            console.log(array)
        }

        $scope.saveSettings = function () {
            //// Save settings in service
            //settingsService.setSettings({
            //    site:    $scope.selectedSites,
            //    region:  $scope.selectedRegions,
            //    type:    $scope.selectedTypes,
            //    minRent: $scope.slider.minValue,
            //    maxRent: $scope.slider.maxValue
            //});

            var newSettings = {
                site:    $scope.selectedSites,
                region:  $scope.selectedRegions,
                type:    $scope.selectedTypes,
                minRent: $scope.slider.minValue,
                maxRent: $scope.slider.maxValue,
                emailFrequency: $scope.selectedFrequency
            };

            if (authenticationService.isUserLoggedIn()) {
                // Save settings in user table
                updateUserSettings(newSettings).then(function (response) {
                    console.log(response)
                    switch (response.status) {
                        case 404:
                            // User not found
                            console.log(response.data)
                            break;
                        case 403:
                            // Membership expired
                            console.log(response.data)
                            break;
                        case 200:
                            // OK
                            settingsService.setSettings(response.data)
                            $location.path("/results");
                            break;
                        default:
                            break;
                    }
                });
            } else {
                // Just set settings
                settingsService.setSettings(newSettings)
                $location.path("/results");
            }
        };

        function updateUserSettings(newSettings) {
            return $http({
                method: 'POST',
                url: '/user/update/settings',
                headers: {
                    'Authorization': authenticationService.getUserToken()
                },
                data: newSettings
            })
            .then(
                // Success callback
                function (response) {
                    return response;
                },
                // Error callback
                function (response) {
                    return response;
                }
            );
        }

    }]
);

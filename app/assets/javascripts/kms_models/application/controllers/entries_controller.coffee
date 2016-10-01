EntriesController = ($scope, $state, Restangular, $stateParams, Alertify, ErrorsService) ->
  $scope.modelStore = Restangular.all('models')
  $scope.store = Restangular.one("models", $stateParams.modelId).all("entries")
  $scope.editorOptions =
    filebrowserUploadUrl: '/kms/assets/ckeditor'

  #Restangular.all('users').customGET('kms_user').then (current_user) ->
    #$scope.currentUser = current_user
    #$scope.currentUser.admin = $scope.currentUser.role == 'admin'

  $scope.entriesSortableOptions =
    orderChanged: (event)->
      for entry, index in event.dest.sortableScope.modelValue
        entry_copy =
          id: entry.id
          position: index
        Restangular.restangularizeElement($scope.model, entry_copy, 'entries').put()

  $scope.modelStore.get($stateParams.modelId).then (model)->
    $scope.model = model
    fields = $scope.getAssociationFields(model)
    _.each fields, (field)->
      $scope[field.liquor_name] = [] # pre-init
      Restangular.one("models", field.class_name).all("entries").getList().then (entries)->
        $scope[field.liquor_name] = entries
        $scope.initAssociationField(field)

  $scope.initAssociationField = (field)->
    if field.type == 'Kms::HasManyField'
      $scope.entry.values[field.liquor_name] = _.filter $scope[field.liquor_name], (element)->
        _.contains $scope.entry.values[field.liquor_name], element.id.toString()
    else
      $scope.entry.values[field.liquor_name] = _.find $scope[field.liquor_name], (element)->
        $scope.entry.values[field.liquor_name] == element.id.toString()

  $scope.store.getList().then (entries)->
    $scope.entries = entries

  if $stateParams.id
    $scope.store.get($stateParams.id).then (entry)->
      $scope.entry = entry
  else
    $scope.entry = {values: {}}

  $scope.getAssociationFields = (model)->
    _.filter model.fields, (field) -> field.type == 'Kms::HasManyField' or field.type == 'Kms::BelongsToField'

  $scope.getFieldTemplateName = (field)->
    typeSplitted = field.type.split '::'
    _.snakeCase(typeSplitted[typeSplitted.length - 1])

  $scope.create = ->
    fd = new FormData
    if $scope.entry.slug
      fd.append("entry[slug]", $scope.entry.slug)
    for key, value of $scope.entry.values
      fd.append("entry[values][#{key}]", value || '')
    $scope.store.withHttpConfig({ transformRequest: angular.identity }).post(fd, null, {"Content-Type": undefined}).then ->
      $state.go('models.entries', modelId: $scope.model.id)
    ,(response)->
      Alertify.error(ErrorsService.prepareErrorsString(response.data.errors))

  $scope.update = ->
    fd = new FormData
    if $scope.entry.slug
      fd.append("entry[slug]", $scope.entry.slug)
    for key, value of $scope.entry.values
      continue if value == undefined
      if value
        if value.constructor.name == 'Array'
          for element in value
            id = if element.constructor.name == 'Object' then element.id else element
            fd.append("entry[values][#{key}][]", id)
        else if value.constructor.name != 'Object'
          fd.append("entry[values][#{key}]", value || '')
      else
        fd.append("entry[values][#{key}]", value || '')
    $scope.entry.withHttpConfig({ transformRequest: angular.identity }).post('', fd, '', {"Content-Type": undefined}).then ->
      $state.go('models.entries', modelId: $scope.model.id)
    ,(response)->
      Alertify.error(ErrorsService.prepareErrorsString(response.data.errors))

  $scope.destroy = (entry)->
    if(confirm('Вы уверены?'))
      entry.remove().then ->
        $scope.entries = _.without($scope.entries, entry)



angular.module('KMS')
    .controller('EntriesController', ['$scope', '$state', 'Restangular', '$stateParams', 'Alertify', 'ErrorsService', EntriesController])

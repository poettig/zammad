class App.TicketStats extends App.Controller
  elements:
    '.js-userTab': 'userTabButton'
    '.js-orgTab': 'orgTabButton'
    '.js-user': 'userTab'
    '.js-org': 'orgTab'

  events:
    'click .js-userTab': 'showUserTab'
    'click .js-orgTab':  'showOrgTab'

  constructor: ->
    super

    # subscribe and reload data / fetch new data if triggered
    if @user
      @subscribeIdUser = App.User.full( @user.id, @load, false, true )
    else if @organization
      @subscribeIdOrganization = App.Organization.full( @organization.id, @load, false, true )

  release: =>
    if @subscribeIdUser
      App.User.unsubscribe(@subscribeIdUser)
    if @subscribeIdOrganization
      App.Organization.unsubscribe(@subscribeIdOrganization)

  load: (object) =>
    if @organization
      ajaxKey = "org_#{@organization.id}"
      data =
        organization_id: @organization.id
    else
      ajaxKey = "user_#{@user.id}"
      data =
        user_id:         @user.id
        organization_id: @user.organization_id
    @ajax(
      id:          'ticket_stats_' + ajaxKey
      type:        'GET'
      url:         @apiPath + '/ticket_stats'
      data:        data
      processData: true
      success:     (data) =>
        App.Collection.loadAssets( data.assets )
        @render(data)
      )

  showOrgTab: =>
    @userTabButton.removeClass('active')
    @orgTabButton.addClass('active')
    @userTab.addClass('hide')
    @orgTab.removeClass('hide')

  showUserTab: =>
    @userTabButton.addClass('active')
    @orgTabButton.removeClass('active')
    @userTab.removeClass('hide')
    @orgTab.addClass('hide')

  render: (data) =>

    @html App.view('widget/ticket_stats')(
      user:         @user
      user_total:   data.user_tickets_open_ids.length + data.user_tickets_closed_ids.length
      organization: @organization
      org_total:    data.org_tickets_open_ids.length + data.org_tickets_closed_ids.length
    )

    limit = 5
    iconClass = ''
    if data.user_tickets_open_ids.length is 0 && data.user_tickets_closed_ids.length > 0
      iconClass = 'mood icon supergood-color'
    new TicketStatsList(
      el:         @$('.js-user-open-tickets')
      user:       @user
      head:       'Open Tickets'
      iconClass:  iconClass
      ticket_ids: data.user_tickets_open_ids
      limit:      limit
    )
    new TicketStatsList(
      el:         @$('.js-user-closed-tickets')
      user:       @user
      head:       'Closed Tickets'
      ticket_ids: data.user_tickets_closed_ids
      limit:      limit
    )
    new TicketStatsFrequency(
      el:                    @$('.js-user-frequency')
      user:                  @user
      ticket_volume_by_year: data.user_ticket_volume_by_year
    )

    iconClass = ''
    if data.org_tickets_open_ids.length is 0 && data.org_tickets_closed_ids.length > 0
      iconClass = 'mood icon supergood-color'
    new TicketStatsList(
      el:         @$('.js-org-open-tickets')
      user:       @user
      head:       'Open Tickets'
      iconClass:  iconClass
      ticket_ids: data.org_tickets_open_ids
      limit:      limit
    )
    new TicketStatsList(
      el:         @$('.js-org-closed-tickets')
      user:       @user
      head:       'Closed Tickets'
      ticket_ids: data.org_tickets_closed_ids
      limit:      limit
    )
    new TicketStatsFrequency(
      el:                    @$('.js-org-frequency')
      user:                  @user
      ticket_volume_by_year: data.org_ticket_volume_by_year
    )

class TicketStatsList extends App.Controller
  events:
    'click .js-showAll': 'showAll'

  constructor: ->
    super
    @render()

  render: =>

    ticket_ids_show = []
    if !@all
      count = 0
      for ticket_id in @ticket_ids
        count += 1
        if count <= @limit
          ticket_ids_show.push ticket_id
    else
      ticket_ids_show = @ticket_ids

    @html App.view('widget/ticket_stats_list')(
      user:            @user
      head:            @head
      iconClass:       @iconClass
      ticket_ids:      @ticket_ids
      ticket_ids_show: ticket_ids_show
      limit:           @limit
    )

    @ticketPopups()

  showAll: (e) =>
    e.preventDefault()
    @all = true
    @render()

class TicketStatsFrequency extends App.Controller
  constructor: ->
    super
    @render()

  render: (data) =>

    # find 100%
    max = 0
    for item in @ticket_volume_by_year
      if item.closed > max
        max = item.closed
      if item.created > max
        max = item.created

    for item in @ticket_volume_by_year
      item.created_in_percent = 100 / max * item.created
      item.closed_in_percent  = 100 / max * item.closed

    @html App.view('widget/ticket_stats_frequency')(
      ticket_volume_by_year: @ticket_volume_by_year.reverse()
    )

class ReportsController < ApplicationController
before_filter :authorize, :except => [:login]


  def index
    list
    render :action => 'list'
  end

  # # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  # verify :method => :post, :only => [ :destroy, :create, :update ],
  #        :redirect_to => { :action => :list }

  def list
    limit = 200
    @report_pages = Paginator.new self, Report.count, limit, params[:page]
    @reports = Report.find :all, :order => "category desc, name", :limit => @report_pages.items_per_page, :offset => @report_pages.current.offset
  end

  def show
    @report = Report.find(params[:id])
    @records = Report.connection.execute(sprintf(@report.sql, params[:param] || @report.param_default))
    @lookups = {} 
    @report.lookups.split.each do |r|   # original lookups string sample: "id:34 name:34:id"
      a = r.split(":")
      h = Hash.new
      h[:link_field_name] = a[0]
      h[:report_id] = a[1]
      h[:param_field_name] = a[2]
      @lookups[a[0]] = h
    end if @report.lookups
    
#breakpoint 
  end

  def new
    @report = Report.new
  end

  def create
    @report = Report.new(params[:report])
    if @report.save
      flash[:notice] = 'Report was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @report = Report.find(params[:id])
  end

  def update
    @report = Report.find(params[:id])
    if @report.update_attributes(params[:report])
      flash[:notice] = 'Report was successfully updated.'
      redirect_to :action => 'show', :id => @report
    else
      render :action => 'edit'
    end
  end

  def destroy
    Report.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end

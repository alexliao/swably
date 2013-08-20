class ReportsController < ApplicationController
  before_filter :authorize, :except => [:login]

  # GET /reports
  # GET /reports.json
  def index
    @reports = Report.find :all, :order => "category desc, name"

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @reports }
    end
  end

  # GET /reports/1
  # GET /reports/1.json
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

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @report }
    end
  end

  # GET /reports/new
  # GET /reports/new.json
  def new
    @report = Report.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @report }
    end
  end

  # GET /reports/1/edit
  def edit
    @report = Report.find(params[:id])
  end

  # POST /reports
  # POST /reports.json
  def create
    @report = Report.new(params[:report])

    respond_to do |format|
      if @report.save
        format.html { redirect_to @report, notice: 'Report was successfully created.' }
        format.json { render json: @report, status: :created, location: @report }
      else
        format.html { render action: "new" }
        format.json { render json: @report.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /reports/1
  # PUT /reports/1.json
  def update
    @report = Report.find(params[:id])

    respond_to do |format|
      if @report.update_attributes(params[:report])
        format.html { redirect_to @report, notice: 'Report was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @report.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /reports/1
  # DELETE /reports/1.json
  def destroy
    @report = Report.find(params[:id])
    @report.destroy

    respond_to do |format|
      format.html { redirect_to reports_url }
      format.json { head :no_content }
    end
  end
end
module Ganttiot
  module IssuesControllerPatch
    def self.included(base)
      base.prepend(InstanceMethods)
    end

    module InstanceMethods
      def new
        session[:return_to] = params[:return_to]
        super
      end

      def create
        unless User.current.allowed_to?(:add_issues, @issue.project, :global => true)
          raise ::Unauthorized
        end
        call_hook(:controller_issues_new_before_save, { :params => params, :issue => @issue })
        @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
        if @issue.save
          call_hook(:controller_issues_new_after_save, { :params => params, :issue => @issue})
          respond_to do |format|
            format.html {
              render_attachment_warning_if_needed(@issue)
              flash[:notice] = l(:notice_issue_successful_create, :id => view_context.link_to("##{@issue.id}", issue_path(@issue), :title => @issue.subject))

              if session[:return_to]
                redirect_to session[:return_to]
                session[:return_to] = nil
              else
                if params[:continue]
                  url_params = {}
                  url_params[:issue] = {:tracker_id => @issue.tracker, :parent_issue_id => @issue.parent_issue_id}.reject {|k,v| v.nil?}
                  url_params[:back_url] = params[:back_url].presence

                  if params[:project_id]
                    redirect_to new_project_issue_path(@issue.project, url_params)
                  else
                    url_params[:issue].merge! :project_id => @issue.project_id
                    redirect_to new_issue_path(url_params)
                  end
                else
                  redirect_back_or_default issue_path(@issue)
                end
              end

            }
            format.api  { render :action => 'show', :status => :created, :location => issue_url(@issue) }
          end
          return
        else
          respond_to do |format|
            format.html {
              if @issue.project.nil?
                render_error :status => 422
              else
                render :action => 'new'
              end
            }
            format.api  { render_validation_errors(@issue) }
          end
        end
      end
    end
  end
end
RedmineExtensions::PatchManager.register_controller_patch 'IssuesController', 'Ganttiot::IssuesControllerPatch'
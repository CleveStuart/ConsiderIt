class Activity < ActiveRecord::Base
  acts_as_tenant(:account)

  belongs_to :action, :polymorphic=>true
  belongs_to :user

  def self.build_from!(object)
    return nil if object.account_id.nil?

    if object.class.name != 'User'
      existing = Account.find(object.account_id).activities.where(:action_type => object.class.name, :action_id => object.id, :user_id => object.user_id).first
      if existing
        existing.destroy
      end
    end
    a = self.new
    a.action_id = object.id 
    a.action_type = object.class.name 
    if object.class.name != 'User'
      a.user_id = object.user_id
    end
    a.account_id = object.account_id
    a.created_at = object.created_at
    a.save
    a
  end

  def obj
    action_type.constantize.find(action_id)
  end  

  def title
    case action_type
    when 'Proposal'
      if user
        "#{user.username} contributed a new proposal"
      else
        "New proposal added"
      end
    when 'Point'
      "#{user.username} wrote a new point for \"#{obj.proposal.title}\""
    when 'Position'
      "#{user.username} #{obj.stance_name_singular} \"#{obj.proposal.title}\""
    when 'Inclusion'
      "#{user.username} included a point by #{obj.point.hide_name || !obj.point.user ? '[hidden]' : obj.point.user.username} for \"#{obj.proposal.title}\""
    when 'Reflect::ReflectBulletRevision'
      "#{user ? user.username : 'Anonymous'} summarized a comment by #{obj.comment.user.username}"
    when 'Comment'
      #TODO: handle commentable type
      "#{user ? user.username : 'Anonymous'} commented on an {item} by #{obj.root_object.user.username} for \"#{obj.root_object.proposal.title}\""      
    when 'User'
      "Welcome to #{obj.name}!"      
    else
      raise "Don't know about this"
    end
  end

  def description
    case action_type
    when 'Proposal'
      "\"#{obj.title}\"."
    when 'Point'
      "\"#{obj.nutshell}\"."
    when 'Position'
      ""
    when 'Inclusion'
      "The point states \"#{obj.point.nutshell}\". #{obj.point.inclusions.count - 1} others have included this point."
    when 'Reflect::ReflectBulletRevision'
      "#{user ? user.username : 'Anonymous'} believes that #{obj.comment.user.username} said \"#{obj.text}\"."
    when 'Comment'
      #TODO: handle commentable
      "#{user.username} commented on an {item} by #{obj.root_object.hide_name || !obj.root_object.user ? '[hidden]' : obj.root_object.user.username} for \"#{obj.root_object.proposal.title}\""      
    when 'User'
      "#{obj.account.users.where('created_at < ' + created_at.to_s).count} other people have joined."      
    else
      raise "Don't know about this"
    end
  end

  #TODO: get commentable path
  def url(host)
    helper = Rails.application.routes.url_helpers

    case action_type
    when 'Proposal'
      helper.proposal_url(obj.long_id, :host => host)
    when 'Point'
      helper.proposal_point_url(obj.proposal.long_id, obj.id, :host => host)
    when 'Position'
      ""
    when 'Inclusion'
      helper.proposal_point_url(obj.proposal.long_id, obj.point_id, :host => host)
    when 'Reflect::ReflectBulletRevision'
      #obj.comment.commentable_path
      helper.proposal_url(obj.comment.root_object.proposal.long_id, :host => host)
    when 'Comment'
      #obj.comment.commentable_path
      helper.proposal_url(obj.root_object.proposal.long_id, :host => host)
    when 'User'
      helper.root_url(:host => host)  
    else
      raise "Don't know about this"
    end
  end

end
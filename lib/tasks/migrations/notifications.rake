#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

namespace :notifications do

  task :send_out_base_tweets => :environment do
    Account.where(:tweet_notifications => true).each do |account|
      account.proposals.order(:created_at).each do |prop|
        if prop.positions.published.count > 0
          pp 'POSTING TO TWITTER'
          msg = new_published_proposal_tweet(prop)
          pp msg
          post_to_twitter_client(account, msg)
        end
      end
    end
  end

  task :migrate_to_follow_messaging_system => :environment do

    # logger = Logger.new(STDOUT)
    # logger.level = Logger::DEBUG
    # ActiveRecord::Base.logger = logger
    # ActionMailer::Base.logger = logger
    # ActionController::Base.logger = logger

    #for each comment, subscribe commenter to point
    Comment.all.each do |o|
      begin
        commentable = o.root_object
        o.follow!(o.user, :follow => true, :explicit => false)
        if commentable.respond_to?(:follow!) && (!commentable.respond_to?(:published) || commentable.published)
          commentable.follow!(o.user, :follow => true, :explicit => false)
        end
      rescue
        pp "Couldn\'t create Follow for #{o.commentable_type} #{o.commentable_id}"
      end
    end

    #for each inclusion, subscribe includer to point
    Inclusion.all.each do |o|
      point = o.point
      if point && point.published && point.user_id != o.user_id
        point.follow!(o.user, :follow => true, :explicit => false)
      end
    end

    #for each point, subscribe author to point
    Point.published.each do |o|
      if o.user
        o.follow!(o.user, :follow => true, :explicit => false)
      end
    end

    #for each proposal, subscribe author to proposal
    Proposal.all.each do |o|
      if o.user && o.positions.published.where(:user_id => o.user.id).count > 0 && o.positions.published.where(:user_id => o.user.id).first.notification_point_subscriber
        o.follow!(o.user, :follow => true, :explicit => false)
      end
    end

    #for each position, subscribe author to proposal if notification_point_subscriber is true
    Position.published.where(:notification_point_subscriber => true ).each do |o|
      o.proposal.follow!(o.user, :follow => true, :explicit => false)
    end
  end

end
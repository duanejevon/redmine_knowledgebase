class KbArticle < ActiveRecord::Base
  unloadable

  self.table_name = "kb_articles"

  validates_presence_of :title
  validates_presence_of :category_id

  belongs_to :project
  belongs_to :category, :class_name => "KbCategory"
  belongs_to :author,   :class_name => 'User', :foreign_key => 'author_id'
  belongs_to :updater,  :class_name => 'User', :foreign_key => 'updater_id'

  acts_as_viewed
  acts_as_rated :no_rater => true
  acts_as_taggable
  acts_as_attachable
  acts_as_watchable
  acts_as_searchable :columns => [ "kb_articles.title", "kb_articles.content"],
                     :include => [ :project ],
                     :order_column => "kb_articles.id",
                     :date_column => "kb_articles.created_at",
                     :permission => nil

  acts_as_event :title => Proc.new {|o| status = (o.new_status ? "(#{l(:label_new_article)})" : "(#{l(:label_article_updated)})"); "#{status} #{l(:label_title_articles)} ##{o.id} - #{o.title}" },
                :description => :summary,
				:datetime => :updated_at,
                :type => 'articles',
                :url => Proc.new { |o| {:controller => 'articles', :action => 'show', :id => o.id, :project_id => o.project} }

  acts_as_activity_provider :find_options => {:include => :project},
							:author_key => :author_id,
							:type => 'articles',
                            :timestamp => :updated_at,
                            :permission => :view_articles

  has_many :comments, :as => :commented, :dependent => :delete_all, :order => "created_on"

  # This overrides the instance method in acts_as_attachable
  def attachments_visible?(user=User.current)
    true
  end

  def attachments_deletable?(user=User.current)
    user.logged?
  end
  
  def recipients
    notified = []
    # Author and assignee are always notified unless they have been
    # locked or don't want to be notified
    notified << author if author
    notified = notified.select {|u| u.active? && u.notify_about?(self)}
    notified.uniq!
    notified.collect(&:mail)
  end
  
  def new_status
    if self.updater_id == 0
		true
	end
  end
end

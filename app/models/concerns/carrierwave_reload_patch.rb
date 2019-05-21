
module CarrierwaveReloadPatch
  # This clobbers the recent Carrierwave versions' behavior of destroying the mounter cache
  # when a model is reloaded. In this app, the writeback fires in between the act of
  # updating the database and actually storing the files, and when it reloads the model
  # the cached image references would otherwise be dropped from memory, breaking uploads.
  def reset_reload_method!
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def reload(*)
        super
      end
    RUBY
  end
end

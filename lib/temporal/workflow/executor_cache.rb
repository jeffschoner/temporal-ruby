class ExecutorCache
  def initialize
    @cache = Hash.new
  end

  def add(run_id, executor)
    @cache[run_id] = executor
  end

  def include?(run_id)
    @cache.include?(run_id)
  end

  def get(run_id)
    @cache[run_id]
  end
end
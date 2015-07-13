namespace :pancakes do
  namespace :stacks do
    desc 'up+down a bunch of stacks'
    task :spin_N_stacks, [:n] do |t,args|
      n = args[:n].to_i
      File.open('/tmp/pk-test.log', 'a') {|f| f.puts "\n\n\n#{Time.now}\n#{"&"*80}\nstarting test" }
      n.times do |i|
        br = 'chore/97589424/get-banyan-working'
        stack = Pancakes::Stack.create_with_git_strings(
          jarvis: br,
          banyan: br,
          desired_state: :running,
          services: Pancakes::Services.banyan_services,
        )
        Delayed::Job.enqueue(Pancakes::Background::BringUpJob.new(stack.id))
        Delayed::Job.enqueue(Pancakes::Background::BringDownJob.new(stack.id, destroy: false))
      end
    end
  end
end

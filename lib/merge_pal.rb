#!/usr/bin/env ruby

require 'git_repo'
require 'js_base/text_editor'

class MergePalApp

  def find_git_root
    @repo = GitRepo.new
  end

  def file_name(f, absolute = false)
    if absolute
      f = File.join(@repo.basedir,f)
    end
    f
  end

  def parse
    text,_ = scall('git status --porcelain')
    pr("Git reports:\n%s\n",text) if @verbose

    files = []

    lines = text.split("\n")
    lines.each do |x|
      gp = GitParser.new(x)
      # The first two characters are the status
      status = gp.parse_chars(2)
      gp.parse(' ')
      path1 = gp.parse_path()
      path2 = nil
      if gp.read_if(' -> ')
        path2 = gp.parse_path()
      end

      next if (status != 'UU' && status != 'AA')
      files << file_name(path1,true)
    end
    files

  end

  def find_conflict(x)
    tx = FileUtils.read_text_file(x)
    lines = tx.lines
    lines.each_with_index do |y,i|
      if y.start_with?('<<<<<<<') || y.start_with?('>>>>>>>')
        return [x,i]
      end
    end
    nil
  end

  def run(argv = nil)
    argv ||= ARGV
    p = Trollop::Parser.new do
        opt :add, "add files (after conflicts fixed)"
        opt :verbose, "verbose"
    end

    options = Trollop::with_standard_exception_handling p do
      p.parse argv
    end

    add_resolved = options[:add]
    verbose = options[:verbose]
    @verbose = verbose

    find_git_root
    files = parse
    while true
      files ||= parse

      pr("(files=%s)\n",d(files)) if @verbose
      c = nil
      files.each do |x|
        c = find_conflict(x)
        break if c
      end

      if !c
        if add_resolved
          files.each do |f|
            # Mark as conflict resolved
            cmd = "git add #{f}"
            puts("Marking resolved: #{File.basename(f)}")
            system(cmd)
          end
        else
          puts("No more merge conflicts found; rerun with -a to mark resolved")
        end
        break
      end

      f,line_num = c

      if add_resolved
        pr("File %s still has merge conflict!\n",file_name(f))
        break
      end

      printf("[ %-30s ]  e)dit q)uit",File.basename(f))
      cmd = RubyBase.get_user_char('q')
      puts

      case cmd
      when 'e'
        editor = TextEditor.new(f)
        editor.line_number = 1 + line_num
        editor.edit
        f2,_ = find_conflict(f)
        if !f2
          files = nil
        end
      when 'q'
        break
      else
        puts "Invalid choice!"
      end
    end
  end
end


if __FILE__ == $0
  MergePalApp.new.run()
end


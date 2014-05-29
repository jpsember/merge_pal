#!/usr/bin/env ruby

require 'js_base/test'
require 'merge_pal'
require 'backup_set'

class TestMergePal < Test::Unit::TestCase

  def setup
    enter_test_directory('__mergepal_test__/myrepo')

    file=<<-eos
Four score and seven years ago our fathers brought forth on this continent a
new nation, conceived in liberty, and dedicated to the proposition that all
men are created equal.

Now we are engaged in a great civil war, testing whether that nation, or any
nation so conceived and so dedicated, can long endure. We are met on a great
battlefield of that war. We have come to dedicate a portion of that field,
as a final resting place for those who here gave their lives that that nation
might live. It is altogether fitting and proper that we should do this.
    eos
    FileUtils.write_text_file('Lincoln1',file)
    file=<<-eos
But, in a larger sense, we can not dedicate, we can not consecrate, we can
not hallow this ground. The brave men, living and dead, who struggled here,
have consecrated it, far above our poor power to add or detract. The world
will little note, nor long remember what we say here, but it can never forget what they did here. It is for us the living, rather, to be dedicated here to the unfinished work which they who fought here have thus far so nobly advanced. It is rather for us to be here dedicated to the great task remaining before us—that from these honored dead we take increased devotion to that cause for which they gave the last full measure of devotion—that we here highly resolve that these dead shall not have died in vain—that this nation, under God, shall have a new birth of freedom—and that
government of the people, by the people, for the people, shall not perish
from the earth.
    eos
    FileUtils.write_text_file('Lincoln2',file)
    @swizzler = Swizzler.new
    @swizzler.add("BackupSet","get_home_dir") {
      '..'
    }
    @swizzler.add('TextEditor','edit') do
      path = self.path
      x = FileUtils.read_text_file(path)
      x << "These lines are new,\nadded by our swizzled edit operation\n"
      FileUtils.write_text_file(path,x)
    end

  end

  def teardown
    @swizzler.remove_all
    leave_test_directory
  end


  # These commands built a git repository with a bit of a history,
  # within the current directory.
  #
  @@cmds_start = <<-eos
    ##################################
    git init
    cp Lincoln1 foo
    git add *
    git commit -m 'initial commit'
    ##################################
eos

  def make(script)
    scalls(@@cmds_start + script, false)
  end

  def record(message="", prefix=nil, args_str='')
    IORecorder.new(prefix).perform do
      puts
      puts
      printf("Recording unit test; %s (prefix=%s, arguments=%s)\n",message,prefix,args_str)
      MergePalApp.new().run(args_str.split)
    end
  end

  def test__M
    make("echo '1' >> foo")
    record("Status is '_M'")
  end

  def test__D
   make("rm foo")
    record("Status is '_D'")
  end

  def test_M_
    c= <<-eos
      echo "1" >> foo
      git add foo
eos
    make(c)
    record("Status is 'M_'")
  end

# I can't produce 'MM'

  def test_MD
    c= <<-eos
echo "1" >> foo
git add foo
rm foo
eos
    make(c)
    record("Status is 'MD'")
  end


  def test_A_
    c= <<-eos
 echo "1" >> foo2
git add foo2
eos
    make(c)
    record("Status is 'A_'")
  end

  def test_AM
    c= <<-eos
echo "1" >> foo2
git add foo2
echo "1" >> foo2
eos
    make(c)
    record("Status is 'AM'")
  end


  def test_AD
    c= <<-eos
echo "1" >> foo2
git add foo2
rm foo2
eos
    make(c)
    record("Status is 'AD'")
  end

  def test_D_
    c= <<-eos
git rm foo
eos
    make(c)
    record("Status is 'D_'")
  end

# I can't produce 'DM' deleted from index

  def test_R_
    c= <<-eos
git mv foo foo2
eos
    make(c)
    record("Status is 'R_'")
  end

  def test_RM
    c= <<-eos
git mv foo foo2
echo "1" >> foo2
eos
    make(c)
    record("Status is 'RM'")
  end

  def test_RD
    c= <<-eos
git mv foo foo2
rm foo2
eos
    make(c)
    record("Status is 'RD'")
  end


# I can't produce 'C_' copied in index
# I can't produce 'CM' copied in index
# I can't produce 'CD' copied in index

  def test_DD
    c= <<-eos
git checkout -b tmp
git mv foo x
git commit -m 'rename to x'
git checkout -
git mv foo y
git commit -m 'rename to y'
git merge tmp -m 'merging'
eos
    make(c)
    record("Status is 'DD', 'AU', 'UA'")
  end

  def test_UD
    c= <<-eos
git co -b 'branch'
git rm foo
git commit -m 'remove foo from branch'
git co -
echo "3" >> foo
git add foo
git commit -m 'modify foo on master'
git merge branch1 -m 'merging branch to master'
eos
    make(c)
    record("Status is 'UD'")
  end

  def test_DU
    c= <<-eos
git co -b 'branch'
echo "1" >> foo
git commit -am 'modified foo on branch'
git co -
git rm foo
git commit -m 'remove foo in master'
git merge branch -m 'merging'
eos
    make(c)
    record("Status is 'DU'")
  end

  def test_AA
    c= <<-eos
git co -b 'branch'
echo "2" >> foo2
git add foo2
git commit -am 'add foo2 on branch'
git co -
echo "1" >> foo2
git add foo2
git commit -am 'add different foo2 to master'
git merge branch -m 'merging'
eos
    make(c)
    record("Status is 'AA'")
  end

  def test_UU
    c= <<-eos
git co -b 'branch'
echo "2" >> foo
git commit -am 'modifying foo on branch'
git co -
echo "3" >> foo
git commit -am 'modifying foo differently on master'
git merge branch
eos
    make(c)
    record("Status is 'UU'")
  end

  def test_untracked
    c= <<-eos
echo "2" >> foo2
eos
    make(c)
    record("Status is '??'")
  end


  def unused_test_depth_1
    make(@@cmds_2)
    record("Calling with depth 1",nil,'-d 1')
  end

  def unused_test_no_forget
    make(@@cmds_2)
    record("First of repeated call",'no_forget_1','-d 1')
    record("Second of repeated call, should remember",'no_forget_2','-d 1')
  end

  def unused_test_forget
    make(@@cmds_2)
    record("First of repeated call, will forget",'forget_1','-d 1')
    record("First of repeated call, now forgetting",'forget_2','-f -d 1')
  end

end

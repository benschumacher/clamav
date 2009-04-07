require File.dirname(__FILE__) + '/../spec_helper'

class ClamAV

  describe "ClamAV" do

    FILES = {
      'robots.txt' => CL_CLEAN,
      'eicar.com'  => 'Eicar-Test-Signature', # EICAR
      'test.txt'   => 'Eicar-Test-Signature', # EICAR in text/plain
      'clam.cab'      => 'ClamAV-Test-File',
      'clam.exe'      => 'ClamAV-Test-File',
      'clam.exe.bz2'  => 'ClamAV-Test-File',
      'clam.zip'      => 'ClamAV-Test-File',
      'clam-v2.rar'   => 'ClamAV-Test-File',
      'clam-v3.rar'   => 'ClamAV-Test-File',
      'clam-p.rar'    => CL_CLEAN,  # encripted RAR
      'clam-ph.rar'    => CL_CLEAN, # encripted RAR with encrypted both file data and headers
      'program.doc'   => 'W97M.Class.EB',
      'Программа.doc' => 'W97M.Class.EB', # filename in UTF-8
    }

    FILES_ENCRYPTED = {
      'clam-p.rar'    => 'Encrypted.RAR',  # encripted RAR
      'clam-ph.rar'    => 'Encrypted.RAR', # encripted RAR with encrypted both file data and headers
    }

    describe "with default options" do
      before(:all) do
        @clam = ClamAV.new
      end

      it "should be instance of Clamav" do
        @clam.should be_instance_of(ClamAV)
      end


      FILES.each do |file, result|
        it "should scan #{file} with result #{result.to_s}" do
           @clam.scanfile(File.join(File.dirname(__FILE__), "../clamav-testfiles/", file)).should == result
        end
      end

      FILES_ENCRYPTED.each do |file, result|
        it "should scan encrypted #{file} with result #{result.to_s}" do
          @clam.scanfile(File.join(File.dirname(__FILE__), "../clamav-testfiles/", file),
            CL_SCAN_STDOPT | CL_SCAN_BLOCKENCRYPTED).should == result
        end
      end

      it "should return signatures count" do
        @clam.signo.should >= 538736 # on 7/04/09
      end

      it "should not reload db when fresh" do
        @clam.reload.should == 0
      end

    end

    describe "with custom options" do

      before(:all) do
        @clam = ClamAV.new(CL_SCAN_STDOPT | CL_SCAN_BLOCKENCRYPTED)
      end

      it "should scan encrypted file with detect" do
        @clam.scanfile(File.join(File.dirname(__FILE__), "../clamav-testfiles/",
            'clam-v3.rar')).should == 'ClamAV-Test-File'
      end

      it "should scan OLE2 file with not detect" do
        @clam.scanfile(File.join(File.dirname(__FILE__), "../clamav-testfiles/", 'program.doc'),
          CL_SCAN_RAW).should == CL_CLEAN
      end

    end

    describe "with custom db options" do

      before(:all) do
        @clam = ClamAV.new(CL_SCAN_STDOPT, CL_DB_STDOPT | CL_DB_PUA)
      end

      it "should detect PUA" do
        @clam.scanfile(File.join(File.dirname(__FILE__), "../clamav-testfiles/",
          'jquery.tooltip.pack.js')).should == 'PUA.Script.Packed-2'
      end

    end


    describe "limits" do
      before(:each) do
        @clam = ClamAV.new
      end

      it "should set limit" do
        @clam.setlimit(CL_ENGINE_MAX_FILES, 1).should == CL_SUCCESS
      end

      it "should do not check archive with two files" do
        @clam.setlimit(CL_ENGINE_MAX_FILES, 1)
        @clam.scanfile(File.join(File.dirname(__FILE__), "../clamav-testfiles/", 'multi.zip')).
          should == CL_CLEAN
      end

      it "should get limit" do
        @clam.getlimit(CL_ENGINE_MAX_FILES).should == 10000
      end

      it "should get db time" do
        Time.at(@clam.getlimit(CL_ENGINE_DB_TIME)).should >= Time.now - 60*60*24 # 1 day
      end

      it "should get tmpdir == nil" do
        @clam.getstring(CL_ENGINE_TMPDIR).should be_nil
      end

      it "should set tmpdir" do
        @clam.setstring(CL_ENGINE_TMPDIR, '/tmp').should == CL_SUCCESS
        @clam.getstring(CL_ENGINE_TMPDIR).should == '/tmp'
      end

    end

  end
end

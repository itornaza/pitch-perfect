//
//  ViewController.swift
//  Pitch Perfect
//
//  Created by Ioannis Tornazakis on 12/12/14.
//  Copyright (c) 2014 Ioannis Tornazakis. All rights reserved.
//

import UIKit
import AVFoundation

class RecordSoundsViewController: UIViewController {

    // MARK: - Properties
    
    var audioRecorder:AVAudioRecorder!
    var recordedAudio:RecordedAudio!
    var pauseFlag:Bool!
    var firstTimeFlag:Bool!
    
    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        // Buttons state
        recordButton.isEnabled = true
        
        // Display appropriate labels
        tapToRecord.isHidden          = false
        recordingInProgress.isHidden  = true
        tapToPause.isHidden           = true
        tapToResume.isHidden          = true
        stopButton.isHidden           = true
        
        // Set up attributes
        pauseFlag       = false
        firstTimeFlag   = true
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var recordingInProgress: UILabel!
    @IBOutlet weak var tapToRecord: UILabel!
    @IBOutlet weak var tapToResume: UILabel!
    @IBOutlet weak var tapToPause: UILabel!

    // MARK: - Actions
    
    /**
        -   This Action controls the recording states which are:
            1.   Initiate recording
            2.   Pause recording
            3.   Resume recording

        -   In this way the microphone icon can be used to
            toggle between these states and appropriate messages
            inform the user what to do next by tapping the mic

        -   Note that the pauseFlag and the firstTimeFlag
            are defining the state transitions
    */
    @IBAction func recordingAudio(_ sender: UIButton) {
        
        // Initial recording state
        if ( pauseFlag == false && (firstTimeFlag == true) ) {
            initiateRecording()
            // Prepare flags for the pause state
            firstTimeFlag   = false
            pauseFlag       = true
            
        // Pause state
        } else if ( pauseFlag == true ) {
            pauseRecording()
            // prepare flags for the resume state
            pauseFlag = false
            
        // Resume state
        } else {
            resumeRecording()
            // Prepare flags for the pause state
            pauseFlag = true
        }
    }
    
    @IBAction func stopRecording(_ sender: UIButton) {
        audioRecorder.stop()
        
        // Display appropriate labels
        tapToRecord.isHidden          = false
        recordingInProgress.isHidden  = true
        tapToPause.isHidden           = true
        tapToResume.isHidden          = true
        stopButton.isHidden           = true
        
        // Set up attributes
        pauseFlag       = false
        firstTimeFlag   = true
        
        // Close recording session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false)
        } catch _ {
        }
    }
    
    // MARK: - Helpers
    
    /**
        -   Initializes the recorder with all necessary parameters
            and begins recording for the first time after the
            scene loads
        -   Sets up the file that the recording is stored
    */
    func initiateRecording() {
        // Buttons state
        recordButton.isEnabled = true
        
        // Display appropriate labels
        tapToRecord.isHidden          = true
        recordingInProgress.isHidden  = false
        tapToPause.isHidden           = false
        tapToResume.isHidden          = true
        stopButton.isHidden           = false
        
        // Recording file (unique filename and path)
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let currentDateTime = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "ddMMyyyy-HHmmss"
        let recordingName = formatter.string(from: currentDateTime)+".wav"
        let pathArray = [dirPath, recordingName]
        let filePath = NSURL.fileURL(withPathComponents: pathArray)
        
        // Initiate recording session
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch _ {
        }
        
        // Audio recorder and its parameters
        do {
            try audioRecorder = AVAudioRecorder(url: filePath!, settings: [:])  //(URL: filePath, settings: nil, error: nil)
        } catch _ {
        }
        audioRecorder.isMeteringEnabled = true
        audioRecorder.prepareToRecord()
        
        // This class becomes a delegate of the AVAudioRecorderDelegate
        // and we now can use the function: audioRecorderDidFinishRecording
        // that is implemented in "Delegates" section below
        audioRecorder.delegate = self
        
        // Start recording
        audioRecorder.record()
    }
    
    /**
        Pauses the recording once it has already been initiated
    */
    func pauseRecording() {
        audioRecorder.pause()
        
        // Buttons state
        recordButton.isEnabled = true
        
        // Display appropriate labels
        recordingInProgress.isHidden  = true
        tapToRecord.isHidden          = true
        tapToPause.isHidden           = true
        tapToResume.isHidden          = false
        stopButton.isHidden           = false
        
        //
        pauseFlag = false
    }
    
    /**
        Resumes recording after it has been paused
    */
    func resumeRecording() {
        audioRecorder.record()
        
        // Buttons state
        recordButton.isEnabled = true
        
        // Display appropriate labels
        recordingInProgress.isHidden  = false
        tapToRecord.isHidden          = true
        tapToPause.isHidden           = false
        tapToResume.isHidden          = true
        stopButton.isHidden           = false
        
        pauseFlag = true
    }
    
    // MARK: - Segues
    
    /**
        Prepares the audio data that have been captured in order
        to be transfered by the upcomming segue
    */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "stopRecording") {
            // Send the audio to the PlaySoundsViewController
            let playSoundsVC:PlaySoundsViewController = segue.destination as! PlaySoundsViewController
            let data = sender as! RecordedAudio
            playSoundsVC.receivedAudio = data
        }
    }
}

extension RecordSoundsViewController: AVAudioRecorderDelegate {
    
    /**
     -  Reference to AVAudioRecorderDelegate protocol
     -  Ensures that the segue from the recorder to the player
        is performed if and only if the recording was completed with
        success. Otherwise displays an error message
     */
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        // recording is successful
        if (flag) {
            
            // Save the recorded audio through its constructor
            recordedAudio = RecordedAudio(filePathUrl: recorder.url, title: recorder.url.lastPathComponent)
            
            // Move to the second scene, aka perform segue
            // just after we have finish recording
            self.performSegue(withIdentifier: "stopRecording", sender: recordedAudio)
            
            // Recording is not successful
        } else {
            
            // Buttons state
            recordButton.isEnabled = true
            
            // Display appropriate labels
            tapToRecord.isHidden          = false
            recordingInProgress.isHidden  = true
            tapToPause.isHidden           = true
            tapToResume.isHidden          = true
            stopButton.isHidden           = true
            
            // Set up attributes
            pauseFlag       = false
            firstTimeFlag   = true
        }
    }
}


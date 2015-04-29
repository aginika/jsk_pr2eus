#!/usr/bin/env roseus

(ros::roseus-add-msgs "std_msgs")
(ros::roseus-add-msgs "sound_play")
(ros::roseus-add-msgs "pr2_msgs")
(ros::roseus-add-msgs "actionlib_msgs")
(ros::roseus-add-srvs "std_srvs")
(ros::roseus-add-msgs "diagnostic_msgs")
(load "package://pr2eus/speak.l")

(ros::roseus "battery_warning")

(setq *ac* nil *ac-tm* (ros::time-now)) ;; ac_present > 0
(setq *motor* t) ;; if motors working
(setq *warning-percentage* 5)

(defun play_sound (sound)
  (let ((msg (instance sound_play::SoundRequest :init)))
    (cond
     ((numberp sound)
      (send msg :sound sound))
     (t
      (send msg :sound sound_play::SoundRequest::*play_file*)
      (send msg :arg sound)))
    (send msg :command sound_play::SoundRequest::*play_once*)
    (ros::publish "/robotsound" msg)))

(defun check-power-state-cb (msg)
  (let ((p (send msg :relative_capacity))
	(a (send msg :ac_present))
	(tm (ros::time-now)))
    (ros::ros-info "power-state pc:~A cap:~A" p a)
    (setq *ac* (> a 0))
    (if (or *ac*
	    (> 180.0 (send (ros::time- tm *ac-tm*) :to-sec)))
	(return-from check-power-state-cb nil))
    (setq *ac-tm* tm) ;; check every 3min
    (speak-jp (format nil "でんちのこり~Aパーセントです" p))
    (cond 
	  ((< p 10)
	   (ros::ros-info "need to back to M78 nebula")
	   (play_sound sound_play::SoundRequest::*needs_plugging*)
	   )
	  ((< p 20)
	   (ros::ros-info "less than 20 perrcept")
	   ;;(play_sound sound_play::needs_unplugging)
	   (play_sound (ros::resolve-ros-path "package://piano/notes/E.wav"))
	   (play_sound (ros::resolve-ros-path "package://piano/notes/G.wav"))
	   (play_sound (ros::resolve-ros-path "package://piano/notes/B.wav"))
	   )
	  (t
	   ))))

(defun diag-cb (msg)
  (when (> 180.0 (send (ros::time- (ros::time-now) *ac-tm*) :to-sec))
    (return-from diag-cb nil))
  (let ((battery-statuses (remove-if-not #'(lambda (d)
                                             (substringp "/Power System/Smart Battery"
                                                         (send d :name)))
                                         (send msg :status))))
    ;; check low capacity battery
    (when (not *ac*)
      (let ((warn-batt-names ""))
        (dolist (b battery-statuses)
          (dolist (kv (send b :values))
            (when (and
                   (substringp "Relative State Of Charge" (send kv :key))
                   (> *warning-percentage* (read-from-string (send kv :value))))
              (setq warn-batt-names 
                    (concatenate string
                                 (subseq (send b :name) 28 31)
                                 "と、"
                                 warn-batt-names)))))
        (ros::ros-info (format nil "ばってりー~Aが~A％以下です。" warn-batt-names *warning-percentage*))))

    ;; check dischaged battery when plugged
    (when *ac*
      (let ((warn-batt-names ""))
        (dolist (b battery-statuses)
          (dolist (kv (send b :values))
            (when (and
                   (substringp "Charge Inhibited" (send kv :key))
                   (string= "True" (send kv :value))
              (concatenate string
                           (subseq (send b :name) 28 31)
                           "と、"
                           warn-batt-names)))))
        (ros::ros-info (format nil "ばってりー~Aが充電できていません" warn-batt-names))))))


(ros::rate 1)
(ros::subscribe "/power_state" pr2_msgs::PowerState #'check-power-state-cb)
(ros::subscribe "/diagnostics_agg" diagnostic_msgs::DiagnosticArray #'diag-cb)
(ros::advertise "/robotsound" sound_play::SoundRequest 10)
(ros::advertise "/robotsound_jp" sound_play::SoundRequest 5)
(ros::spin)
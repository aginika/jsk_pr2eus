#!/usr/bin/env python                                                          

import roslib
roslib.load_manifest('jsk_pr2_startup')
import rospy
import twoauth,yaml
from std_msgs.msg import String

# see http://d.hatena.ne.jp/gumilab/20101004/1286154912 to setup CKEY/AKEY
key = yaml.load(open('/var/lib/robot/twitter_acount_pr2jsk.yaml'))
CKEY = key['CKEY']
CSECRET = key['CSECRET']
AKEY = key['AKEY']
ASECRET = key['ASECRET']

def twit(dat):
    rospy.loginfo(rospy.get_name()+" sending %s",dat.data)
    twitter.status_update(dat.data)

if __name__ == '__main__':
    twitter = twoauth.api(CKEY, CSECRET, AKEY, ASECRET)
    rospy.init_node('rostwitter', anonymous=True)
    rospy.Subscriber("pr2twit", String, twit)
    rospy.spin()

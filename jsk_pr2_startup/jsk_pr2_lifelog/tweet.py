#!/usr/bin/env python                                                          

import roslib
roslib.load_manifest('jsk_pr2_startup')
import rospy
import twoauth,yaml
import re
from std_msgs.msg import String

# see http://d.hatena.ne.jp/gumilab/20101004/1286154912 to setup CKEY/AKEY
key = yaml.load(open('/var/lib/robot/twitter_acount_pr2jsk.yaml'))
CKEY = key['CKEY']
CSECRET = key['CSECRET']
AKEY = key['AKEY']
ASECRET = key['ASECRET']

def twit(dat):
    message = dat.data
    rospy.loginfo(rospy.get_name()+" sending %s",message)
    # search word start from / and end with {.jpeg,.jpg,.png,.gif}
    m = re.search('/\S+\.(jpeg|jpg|png|gif)', message)
    if m :
        filename = m.group(0)
        message = re.sub(filename,"",message)
        twitter.status_update_with_media(message, filename)
    else:
        twitter.status_update(message)

if __name__ == '__main__':
    twitter = twoauth.api(CKEY, CSECRET, AKEY, ASECRET)
    rospy.init_node('rostwitter', anonymous=True)
    rospy.Subscriber("pr2twit", String, twit)
    rospy.spin()
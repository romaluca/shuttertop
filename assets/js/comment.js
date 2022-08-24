import * as Utils from './utils'

let Comment = {
    mountedComment(not_scroll) {
        const commentsContainer = document.getElementById("commentsContainer")
        const totals = commentsContainer.getAttribute("data-totals")
        const hide = (totals <= document.getElementsByClassName("comment-container").length)
        document.getElementById("commentsMoreButton").style.display = hide ? null : "block"
        if (document.getElementById("commentsPage") !== null) {
            if (window.innerWidth > Utils.ScreenSize.lg) {
                commentsContainer.style.height = (window.innerHeight - 225) + 'px'
                if (!not_scroll) commentsContainer.scrollTop = commentsContainer.scrollHeight;
            } else if (!not_scroll) window.scrollTo(0, document.body.scrollHeight)
        } else if (document.getElementById("contestPage") !== null) {
            commentsContainer.scrollTop = commentsContainer.scrollHeight;
        }

    },
    updateComment() {
        Comment.mountedComment(true)
    },
    mountedTopics() {
        Comment.updateTopics()
    },
    updateTopics() {
        Utils.checkBackButton()
        const topicId = document.getElementsByClassName("chat-page")[0].getAttribute("data-id") ?? ""
        if (window.innerWidth < Utils.ScreenSize.lg) {
            document.getElementsByClassName("page-content")[0].style.display = topicId != "" ? "none" : "block"
            document.getElementsByClassName("right-bar-comments")[0].style.display = topicId != "" ? "block" : "none"
            document.getElementsByClassName("footerbar")[0].style.display = topicId != "" ? "none" : "block"
        }
        const topic = document.getElementById("topic-" + topicId)
        if (topic != null)
            topic.classList.add("selected")
        var topicList = document.getElementById("topicList")
        if (topicList !== null && window.innerWidth > Utils.ScreenSize.lg) {
            topicList.style.height = (window.innerHeight - 150) + 'px'
        }
    }

}
export default Comment;

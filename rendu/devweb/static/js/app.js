const STORAGE_KEY = "techcorp_ai_conversations";

const chat = document.getElementById("chat");
const input = document.getElementById("messageInput");
const sendButton = document.getElementById("sendButton");
const statusDot = document.getElementById("statusDot");
const statusText = document.getElementById("statusText");
const historyList = document.getElementById("historyList");
const newChatButton = document.getElementById("newChatButton");
const chatTitle = document.getElementById("chatTitle");

let conversations = loadConversations();
let activeConversationId = null;

function createId() {
    return "conv_" + Date.now() + "_" + Math.random().toString(16).slice(2);
}

function scrollToBottom() {
    requestAnimationFrame(() => {
        chat.scrollTop = chat.scrollHeight;
    });
}

function loadConversations() {
    try {
        const raw = localStorage.getItem(STORAGE_KEY);
        return raw ? JSON.parse(raw) : [];
    } catch {
        return [];
    }
}

function saveConversations() {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(conversations));
}

function createConversation() {
    const conversation = {
        id: createId(),
        title: "Nouvelle conversation",
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        messages: [
            {
                role: "assistant",
                content: "Bonjour, je suis l’assistant financier TechCorp. Posez-moi une question sur la finance, le budget, le business ou l’analyse d’entreprise."
            }
        ]
    };

    conversations.unshift(conversation);
    activeConversationId = conversation.id;

    saveConversations();
    renderAll();
}

function getActiveConversation() {
    return conversations.find(conversation => conversation.id === activeConversationId);
}

function setActiveConversation(id) {
    activeConversationId = id;
    renderAll();
}

function deleteConversation(id, event) {
    event.stopPropagation();

    const confirmed = confirm("Supprimer cette conversation ?");
    if (!confirmed) {
        return;
    }

    conversations = conversations.filter(conversation => conversation.id !== id);

    if (activeConversationId === id) {
        activeConversationId = conversations.length ? conversations[0].id : null;
    }

    saveConversations();

    if (!activeConversationId) {
        createConversation();
    } else {
        renderAll();
    }
}

function updateConversationTitle(conversation, firstUserMessage) {
    if (conversation.title === "Nouvelle conversation") {
        conversation.title = firstUserMessage.slice(0, 42);
    }
}

function renderHistory() {
    historyList.innerHTML = "";

    conversations.forEach(conversation => {
        const item = document.createElement("div");
        item.className = "history-item" + (conversation.id === activeConversationId ? " active" : "");
        item.onclick = () => setActiveConversation(conversation.id);

        const title = document.createElement("div");
        title.className = "history-title";

        const strong = document.createElement("strong");
        strong.textContent = conversation.title;

        const span = document.createElement("span");
        span.textContent = new Date(conversation.updatedAt).toLocaleString("fr-FR");

        title.appendChild(strong);
        title.appendChild(span);

        const deleteButton = document.createElement("button");
        deleteButton.className = "delete-chat";
        deleteButton.textContent = "×";
        deleteButton.title = "Supprimer la conversation";
        deleteButton.onclick = event => deleteConversation(conversation.id, event);

        item.appendChild(title);
        item.appendChild(deleteButton);
        historyList.appendChild(item);
    });
}

function renderChat() {
    const conversation = getActiveConversation();

    chat.innerHTML = "";

    if (!conversation) {
        return;
    }

    chatTitle.textContent = conversation.title === "Nouvelle conversation"
        ? "TechCorp AI Chat"
        : conversation.title;

    conversation.messages.forEach(message => {
        addMessageToScreen(message.content, message.role);
    });

    scrollToBottom();
}

function renderAll() {
    renderHistory();
    renderChat();
}

function addMessageToScreen(content, type) {
    const row = document.createElement("div");
    row.className = "message-row" + (type === "user" ? " user-row" : "");

    const wrapper = document.createElement("div");
    wrapper.className = "message-wrapper";

    const sender = document.createElement("div");
    sender.className = "sender";
    sender.textContent = type === "user" ? "Vous" : "TechCorp Phi-Financial";

    const bubble = document.createElement("div");
    bubble.className = "bubble " + (type === "user" ? "user-bubble" : "assistant-bubble");
    bubble.textContent = content;

    wrapper.appendChild(sender);
    wrapper.appendChild(bubble);
    row.appendChild(wrapper);
    chat.appendChild(row);

    scrollToBottom();

    return bubble;
}

function addTypingMessage() {
    const row = document.createElement("div");
    row.className = "message-row";

    const wrapper = document.createElement("div");
    wrapper.className = "message-wrapper";

    const sender = document.createElement("div");
    sender.className = "sender";
    sender.textContent = "TechCorp Phi-Financial";

    const bubble = document.createElement("div");
    bubble.className = "bubble assistant-bubble";
    bubble.innerHTML = '<span class="typing"><span></span><span></span><span></span></span>';

    wrapper.appendChild(sender);
    wrapper.appendChild(bubble);
    row.appendChild(wrapper);
    chat.appendChild(row);

    scrollToBottom();

    return bubble;
}

async function sendMessage() {
    const message = input.value.trim();

    if (!message) {
        return;
    }

    let conversation = getActiveConversation();

    if (!conversation) {
        createConversation();
        conversation = getActiveConversation();
    }

    conversation.messages.push({
        role: "user",
        content: message
    });

    updateConversationTitle(conversation, message);
    conversation.updatedAt = new Date().toISOString();

    addMessageToScreen(message, "user");

    input.value = "";
    input.style.height = "48px";
    sendButton.disabled = true;

    const loadingBubble = addTypingMessage();

    try {
        const messagesForBackend = conversation.messages
            .filter(message => message.role === "user" || message.role === "assistant")
            .map(message => ({
                role: message.role,
                content: message.content
            }));

        const response = await fetch("/api/chat", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                messages: messagesForBackend
            })
        });

        const data = await response.json();

        if (data.answer) {
            loadingBubble.textContent = data.answer;

            conversation.messages.push({
                role: "assistant",
                content: data.answer
            });
        } else {
            loadingBubble.textContent = data.error || "Erreur inconnue.";
            loadingBubble.style.background = "#7f1d1d";
        }
    } catch (error) {
        loadingBubble.textContent = "Erreur : impossible de contacter le backend Flask.";
        loadingBubble.style.background = "#7f1d1d";
    }

    conversation.updatedAt = new Date().toISOString();

    saveConversations();
    renderHistory();

    sendButton.disabled = false;
    input.focus();

    scrollToBottom();
}

async function checkHealth() {
    try {
        const response = await fetch("/health");
        const data = await response.json();

        if (data.ollama_available) {
            statusDot.classList.remove("error");
            statusText.textContent = "Système opérationnel";
        } else {
            statusDot.classList.add("error");
            statusText.textContent = "Ollama indisponible";
        }
    } catch {
        statusDot.classList.add("error");
        statusText.textContent = "Backend indisponible";
    }
}

function useQuickPrompt(text) {
    input.value = text;
    input.focus();
    sendMessage();
}

function setupEventListeners() {
    document.querySelectorAll(".quick-btn").forEach(quickButton => {
        quickButton.addEventListener("click", () => {
            useQuickPrompt(quickButton.dataset.prompt);
        });
    });

    newChatButton.addEventListener("click", createConversation);
    sendButton.addEventListener("click", sendMessage);

    input.addEventListener("input", function () {
        input.style.height = "48px";
        input.style.height = Math.min(input.scrollHeight, 140) + "px";
    });

    input.addEventListener("keydown", function (event) {
        if (event.key === "Enter" && !event.shiftKey) {
            event.preventDefault();
            sendMessage();
        }
    });
}

function initializeApp() {
    setupEventListeners();

    if (!conversations.length) {
        createConversation();
    } else {
        activeConversationId = conversations[0].id;
        renderAll();
    }

    checkHealth();
    setInterval(checkHealth, 15000);
}

initializeApp();